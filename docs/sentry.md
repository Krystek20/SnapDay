# Sentry production setup

SnapDay uploads debug symbols during Release archives. Before archiving:

1. Install the CLI with `brew install getsentry/tools/sentry-cli`.
2. Authenticate with `sentry-cli login`, or expose `SENTRY_AUTH_TOKEN` to the archive build in CI.
3. Expose `SENTRY_ORG` and `SENTRY_PROJECT` as Xcode build settings or CI environment variables.

The archive intentionally fails when the CLI or required project identifiers are unavailable. This prevents shipping a build whose crash reports cannot be symbolicated.

In the Sentry project settings, enable **Prevent Storing of IP Addresses**. The SDK already disables default PII and automatic session tracking, but IP handling is enforced by the Sentry project rather than by the app.
