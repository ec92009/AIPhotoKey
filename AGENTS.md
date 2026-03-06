# AIPhotoKey Repo Instructions

- Commit every meaningful implementation step.
- Push each commit to `origin` immediately after the local commit succeeds.
- Keep commits scoped to a single coherent change whenever practical.
- Use non-interactive git commands only.
- Do not batch unrelated changes into one commit unless explicitly requested.
- Track app versions step by step.
- Current baseline version is `v6.0`.
- Increment the minor version on every meaningful implementation step: `v6.0`, `v6.1`, `v6.2`, ...
- Increment the major version once per day, then resume minor increments from `.0`.
- Keep package metadata aligned using semver-compatible values such as `6.0.0`, `6.1.0`, `7.0.0`.
- Create and push a matching git tag for each versioned step.
