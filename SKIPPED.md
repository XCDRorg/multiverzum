# Skipped security advisories

Advisories that could not be resolved within the project constraints
(yarn `resolutions` / patch-level bumps, no major version bumps).

## ip — SSRF improper categorization in isPublic (high)

- Advisory: https://github.com/advisories/GHSA-2p57-rm9w-gvfp
- Installed: `ip@2.0.0` (via a transitive dependency)
- Reason skipped: the advisory reports `patched: <0.0.0`, i.e. **no fixed
  version exists**. The maintainer has not shipped a release that corrects the
  `isPublic` categorization; the latest published version (`2.0.1`) is still
  within the vulnerable range. There is therefore no version-based remediation
  (resolution or patch bump) available. Left at `2.0.0`; revisit if/when an
  upstream fix is published.

## Notes on `brace-expansion` GHSA-3jxr-9vmj-r5cp / GHSA-mh99-v99m-4gvg (informational)

- brace-expansion is present at three majors (1.x, 2.x, 5.x), each reached
  **only** as a dependency of `minimatch`. Ideally each major would be pinned to
  its own patched release (`1.1.17` / `2.1.3` / `5.0.8`). Yarn 1.22.x, however,
  only honors two-segment selective resolutions (`**/parent/child`); the
  three-segment `**/<grandparent>/minimatch/brace-expansion` form needed to scope
  by minimatch major is silently ignored (verified empirically — the pre-existing
  nested `minimatch`/`semver` entries are likewise no-ops here). brace-expansion's
  only entry point is `minimatch`, so the deepest reachable key is
  `**/minimatch/brace-expansion`, which necessarily applies one version to all
  consumers. It is pinned to `2.1.3`, which satisfies **both** advisories
  (`>=2.1.2` and `>=2.1.3`) and clears every brace-expansion instance in the tree.
  Its public API (`expand(str)`) is unchanged across all majors, so the shared
  minimatch consumers (3.x/5.x/9.x) continue to work — `eslint --print-config`
  was verified to run cleanly. Not a skip; recorded only to explain the single
  forced version rather than per-major pins.

## Notes on `rollup` GHSA-mw96-cpmx-2vgc (informational)

- The "Rollup 4 has Arbitrary File Write via Path Traversal" advisory lists a
  patched range of `>=3.30.0`. This repo only carries rollup 3.x (via
  vite/storybook), and it is pinned to `3.30.0` through a `resolutions` entry,
  which satisfies that range **and** the DOM-clobbering advisory
  (GHSA-gcx4-mw62-g8wm, `>=3.29.5`). No skip needed — recorded here only to
  explain why 3.30.0 (rather than the 3.x-latest 3.29.5) was chosen.
