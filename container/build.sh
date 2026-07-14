#!/usr/bin/env bash
# container/build.sh
# Builds the Third Room images with Podman on the headless rig.
# Two images:
#   localhost/tr-wasm  : the QuickJS->WASM artifact (pinned emsdk 3.1.23)
#   localhost/tr-app   : UBI9-based build+serve image
set -euo pipefail
cd "$(dirname "$0")/.."

ENGINE="${ENGINE:-podman}"   # set ENGINE=docker to override

echo "==> [1/2] Building WASM runtime stage (emscripten/emsdk:3.1.23)"
# Build context is the emscripten subtree so the COPY in Containerfile.wasm
# resolves relative to it.
"$ENGINE" build \
  -f container/Containerfile.wasm \
  -t localhost/tr-wasm:latest \
  .

echo "==> [2/2] Building UBI app image (build + serve)"
"$ENGINE" build \
  -f container/Containerfile \
  -t localhost/tr-app:latest \
  .

echo
echo "Done."
echo "  WASM image : localhost/tr-wasm:latest"
echo "  App  image : localhost/tr-app:latest"
echo
echo "Run the server (serves dist on :3000 with COOP/COEP):"
echo "  $ENGINE run --rm -p 3000:3000 localhost/tr-app:latest"
echo
echo "From your notebook browser, open:  http://<RIG-IP>:3000"
