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

## Notes on `rollup` GHSA-mw96-cpmx-2vgc (informational)

- The "Rollup 4 has Arbitrary File Write via Path Traversal" advisory lists a
  patched range of `>=3.30.0`. This repo only carries rollup 3.x (via
  vite/storybook), and it is pinned to `3.30.0` through a `resolutions` entry,
  which satisfies that range **and** the DOM-clobbering advisory
  (GHSA-gcx4-mw62-g8wm, `>=3.29.5`). No skip needed — recorded here only to
  explain why 3.30.0 (rather than the 3.x-latest 3.29.5) was chosen.
