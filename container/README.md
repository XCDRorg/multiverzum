# Third Room — Podman / UBI Container Setup (headless rig + notebook browser)

This containerizes the whole build+serve flow on your **headless Linux rig** using
Podman and a **Red Hat UBI 9** base, and explains how to view/test it from the
**notebook with the GPU** correctly — including the one non-obvious gotcha
(secure-context / SharedArrayBuffer) that would otherwise silently break the app.

## Topology

```
  headless rig (no GPU)                       notebook (has GPU)
  --------------------                        ------------------
  podman build  ->  tr-wasm  (emsdk 3.1.23)
                ->  tr-app   (UBI9 nodejs-22)
  podman run    ->  serves :3000  <==SSH tunnel==>  browser -> http://localhost:3000
                                                    (WebGL renders on the GPU here)
```

The rig does all CPU work (install, audit, typecheck, build, WASM compile, serve).
The notebook is just a browser. The SSH tunnel makes the rig's `:3000` appear as
`localhost:3000` on the notebook — which is what makes cross-origin isolation work
(see "The secure-context gotcha" below).

## Files

```
container/
  Containerfile          UBI9 build+serve image (multi-stage)
  Containerfile.wasm     QuickJS->WASM artifact, pinned emscripten/emsdk:3.1.23
  serve.json             COOP/COEP headers (mandatory for SharedArrayBuffer)
  build.sh               builds both images with podman
  compose.yaml           podman-compose: `serve` (prod) or `dev` (Vite HMR)
```

## Prerequisites on the rig

```bash
sudo dnf install -y podman podman-compose git-lfs   # Fedora/RHEL
# (Debian/Ubuntu: apt-get install -y podman podman-compose git-lfs)
podman --version
```

Rootless Podman is fine and preferred. No daemon, no root.

## Why UBI 22 and not 20

The Red Hat catalog now marks **`ubi9/nodejs-20` as Deprecated**; `nodejs-22` is
the current supported, signed image. We base on 22. This 2023-era repo still
*targets* the Node 20 runtime line conceptually, but builds cleanly on 22 in
practice. If you ever hit a Node-22-specific break, pin the `engines` field in
package.json and we'll address it in a patch rather than basing on a deprecated
image.

## Why the WASM build is its own image

The QuickJS scripting runtime is compiled with Emscripten, and the repo pins
`emscripten/emsdk:3.1.23` (in `src/engine/scripting/emscripten/build-docker.sh`).
Rather than install emsdk into the UBI image — which means compiling the SDK
against RHEL's toolchain, which is fragile — we build the `.wasm` in a throwaway
stage on the official emsdk image and copy just the artifact into the UBI image.
This preserves upstream build provenance and keeps the UBI image clean.

## Build

```bash
cd ~/thirdroom-main
./container/build.sh          # builds localhost/tr-wasm then localhost/tr-app
```

First build is slow (downloads base images + full yarn install incl. the
git-ref deps from github.com — make sure the rig has outbound network).

### Pin base images by digest (do this once, before trusting builds)

Tags move; digests don't. Lock both bases:

```bash
skopeo inspect docker://registry.access.redhat.com/ubi9/nodejs-22 | jq -r .Digest
skopeo inspect docker://docker.io/emscripten/emsdk:3.1.23          | jq -r .Digest
```

Paste each `sha256:...` into the corresponding `FROM ...@sha256:...` line in the
two Containerfiles. This is the containerized equivalent of the lockfile — it
closes the same supply-chain gap we flagged for the git-ref npm deps.

## Run — production static build (default)

```bash
podman run --rm -p 127.0.0.1:3000:3000 localhost/tr-app:latest
```

Note `127.0.0.1:` — we bind to loopback on the rig, NOT 0.0.0.0. The notebook
reaches it through the SSH tunnel, so the server never listens on the LAN. This
is both more secure and what makes the secure-context trick below work.

## Run — Vite dev server (edit/render loop)

```bash
podman-compose -f container/compose.yaml up dev
```

Live-mounts your working tree (`:Z` handles SELinux relabeling on RHEL/Fedora).
Edits on the rig hot-reload in the browser.

## Viewing from the notebook — the secure-context gotcha

**This is the part that bites everyone.** Third Room uses `SharedArrayBuffer`
for its threaded WASM scripting runtime. Browsers only enable SharedArrayBuffer
when the page is **cross-origin isolated** AND served in a **secure context**.

- `http://localhost:3000` → secure context ✓
- `http://192.168.x.x:3000` (rig's LAN IP) → **NOT** a secure context ✗

So if you just point the notebook at `http://RIG-IP:3000`, the page loads but
threads/scripting silently fail, even though serve.json sets the headers
correctly. The headers are necessary but not sufficient; you also need a secure
context.

**The clean fix: SSH tunnel.** From the notebook:

```bash
ssh -N -L 3000:127.0.0.1:3000 youruser@RIG-IP
```

Now open `http://localhost:3000` on the notebook. The browser sees `localhost`
(secure context ✓), the headers are present (isolation ✓), SharedArrayBuffer
works, and WebGL renders on the notebook's GPU. This also means you never expose
the dev/serve port on the LAN at all.

**Alternative (if you want a real LAN URL): HTTPS with a trusted cert.**

```bash
# on the rig, once:
mkcert -install
mkcert rig.local 192.168.x.x
# then serve over https with those certs (swap `serve` for a TLS-capable serve
# or put Caddy in front). https://RIG-IP is then a secure context.
```

More setup, but gives multiple people on the LAN access. For a solo
rig+notebook loop, the tunnel is simpler and safer.

**Testing-only escape hatch (do not rely on this):** Chrome can be coaxed with
`--unsafely-treat-insecure-origin-as-secure="http://RIG-IP:3000"` plus
`--user-data-dir=/tmp/throwaway`. Fine for a one-off check, wrong for real work.

## Hooking the container into the patch pipeline

The earlier `pipeline/bundle.sh` runs the toolchain directly. To run it *inside*
the container instead (so audit/typecheck/build happen in the exact UBI
environment), exec into a build container:

```bash
podman run --rm -v "$PWD":/opt/app-root/src:Z -w /opt/app-root/src \
  localhost/tr-app:latest bash -lc './pipeline/bundle.sh'
```

The bundle tar.gz lands in your working tree (mounted), and you upload it here
as before. This guarantees the logs I see reflect the same environment the build
actually runs in — no "works on my machine" drift between your host and the
container.

## Security notes specific to the container

- **Rootless Podman + non-root USER 1001 inside.** The image never runs as root
  at runtime; root is used only briefly at build time to `dnf install` OS deps.
- **Loopback-only port binding.** Combined with the SSH tunnel, nothing listens
  on the LAN. This also sidesteps the unpatched Vite dev-server `fs.deny` CVEs
  until we land the Vite 4->6 upgrade (patch 003), because the dev server is
  never network-reachable.
- **Digest-pinned bases** close the image supply-chain gap.
- **No secrets baked in.** Don't `COPY` a `.env` into the image. If the app
  needs runtime config, pass it via `-e` / `--env-file` at `podman run` time.
- The `:Z` volume flag relabels for SELinux. If you're on a non-SELinux distro
  it's a harmless no-op; keep it for portability across the RHEL family.
```
