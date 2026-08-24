# SnapDay validation

Use the repository validation entry points after implementation work:

- `make check` for the fast compile gate.
- `make test` after behavior changes.
- `make validate` before handing off a broad or release-sensitive change.
- For a focused test run, use `./scripts/validate.sh test -only-testing:<TestTarget>`.

Do not use plain `swift test`: SnapDayKit is an iOS package and must be tested through the shared Xcode scheme on an iOS Simulator. The validation script pins the environment and resolved package versions, reuses local caches, and writes test diagnostics to `.build/validation/Results.xcresult`.

Set `SNAPDAY_VERBOSE=1` only when full Xcode build logs are needed. Set `SNAPDAY_ARCHS="arm64 x86_64"` when a universal simulator build is specifically required.
