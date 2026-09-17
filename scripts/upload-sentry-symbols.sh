#!/bin/bash

set -euo pipefail

if [[ "${CONFIGURATION:-}" != "Release" || "${ACTION:-}" != "install" ]]; then
  exit 0
fi

required_variables=(SENTRY_ORG SENTRY_PROJECT DWARF_DSYM_FOLDER_PATH)
for variable in "${required_variables[@]}"; do
  if [[ -z "${!variable:-}" ]]; then
    echo "error: ${variable} is required to upload Sentry debug symbols" >&2
    exit 1
  fi
done

if command -v sentry-cli >/dev/null 2>&1; then
  sentry_cli="$(command -v sentry-cli)"
elif [[ -x /opt/homebrew/bin/sentry-cli ]]; then
  sentry_cli=/opt/homebrew/bin/sentry-cli
elif [[ -x /usr/local/bin/sentry-cli ]]; then
  sentry_cli=/usr/local/bin/sentry-cli
else
  echo "error: sentry-cli is required to upload Sentry debug symbols" >&2
  echo "       Install it with: brew install getsentry/tools/sentry-cli" >&2
  exit 1
fi

"${sentry_cli}" debug-files upload \
  --force-foreground \
  --include-sources \
  "${DWARF_DSYM_FOLDER_PATH}"
