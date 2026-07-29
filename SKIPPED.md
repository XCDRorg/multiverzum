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

## Notes on `brace-expansion` GHSA-3jxr-9vmj-r5cp / GHSA-mh99-v99m-4gvg (informational)

- `brace-expansion` is pulled in at **three incompatible majors** — all via
  `minimatch`: v3 → `brace-expansion@^1` (CJS), v5 → `brace-expansion@^2` (CJS),
  and v9 → `brace-expansion@^5` (**ESM-only**, `"type": "module"`, no `require`
  export). Each major has its own patched line: `>=1.1.16`, `>=2.1.2`, `>=5.0.8`.
- A yarn 1 `resolutions` entry cannot express this per-major split: the only
  forms yarn 1 honours for this deeply-nested dep (`brace-expansion`,
  `minimatch/brace-expansion`, `**/minimatch/brace-expansion`) all **collapse
  every major onto a single version**, which would force the CJS build into the
  ESM `minimatch@9` (or vice-versa) and break `typedoc`. Package-scoped
  `pkg/**/brace-expansion` keys do not apply to the descendant under a
  resolution-forced `minimatch`.
- Instead this was fixed as a **patch-level bump within each major** (allowed by
  the constraints): the pinned `brace-expansion` entries were dropped from
  `yarn.lock` so each declared range re-resolves to its patched latest-in-major
  — `^1.1.7 → 1.1.16`, `^2.0.1 → 2.1.3`, `^5.0.2 → 5.0.8`. Every consumer stays
  inside its own major. No skip needed — recorded here to explain why
  `brace-expansion` is fixed via the lockfile rather than a `resolutions` entry.
