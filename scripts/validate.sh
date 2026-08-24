#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly OUTPUT_DIR="${REPO_DIR}/.build/validation"
readonly DERIVED_DATA_DIR="${OUTPUT_DIR}/DerivedData"
readonly PACKAGES_DIR="${OUTPUT_DIR}/SourcePackages"
readonly RESULT_BUNDLE="${OUTPUT_DIR}/Results.xcresult"
readonly PROJECT="${REPO_DIR}/SnapDay.xcodeproj"
readonly SCHEME="SnapToday"
readonly LOCAL_ARCH="$(uname -m)"

mode="${1:-quick}"
if [[ $# -gt 0 ]]; then
  shift
fi

usage() {
  cat <<'EOF'
Usage: ./scripts/validate.sh [quick|test|full] [xcodebuild options]

  quick  Compile the complete app for a generic iOS Simulator (default).
  test   Run all unit tests on a deterministic simulator destination.
  full   Run unit tests, then compile a Release simulator build.

Examples:
  ./scripts/validate.sh
  ./scripts/validate.sh test
  ./scripts/validate.sh test -only-testing:PlansTests
  SNAPDAY_SIMULATOR="iPhone 16 Pro" ./scripts/validate.sh test
  SNAPDAY_SIMULATOR_OS="18.6" ./scripts/validate.sh test
EOF
}

if [[ "${mode}" != "quick" && "${mode}" != "test" && "${mode}" != "full" ]]; then
  usage >&2
  exit 64
fi

for command in xcodebuild xcrun; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "error: ${command} is required" >&2
    exit 69
  fi
done

if [[ ! -d "${REPO_DIR}/../snapday-core" ]]; then
  echo "error: expected the local SnapDayCore package at ${REPO_DIR}/../snapday-core" >&2
  echo "       Package.swift currently depends on that checkout." >&2
  exit 66
fi

mkdir -p "${OUTPUT_DIR}" "${PACKAGES_DIR}"

export LANG=C
export LC_ALL=C
export TZ=Europe/Warsaw
export SWIFT_DETERMINISTIC_HASHING=1
export NSUnbufferedIO=YES

readonly common_options=(
  -project "${PROJECT}"
  -scheme "${SCHEME}"
  -derivedDataPath "${DERIVED_DATA_DIR}"
  -clonedSourcePackagesDirPath "${PACKAGES_DIR}"
  -disableAutomaticPackageResolution
  -onlyUsePackageVersionsFromResolvedFile
  CODE_SIGNING_ALLOWED=NO
)

xcode_output_options=(-quiet)
if [[ "${SNAPDAY_VERBOSE:-0}" == "1" ]]; then
  xcode_output_options=()
fi

run_build() {
  local configuration="$1"
  shift
  xcodebuild build \
    "${xcode_output_options[@]}" \
    "${common_options[@]}" \
    -configuration "${configuration}" \
    -destination "generic/platform=iOS Simulator" \
    ARCHS="${SNAPDAY_ARCHS:-${LOCAL_ARCH}}" \
    ONLY_ACTIVE_ARCH=YES \
    "$@"
}

run_tests() {
  local simulator_name="${SNAPDAY_SIMULATOR:-iPhone 17 Pro}"
  local simulator_os="${SNAPDAY_SIMULATOR_OS:-$(xcrun --sdk iphonesimulator --show-sdk-version)}"

  if ! xcrun simctl list devices available | grep -F "${simulator_name} (" >/dev/null; then
    echo "error: iOS Simulator '${simulator_name}' is not installed." >&2
    echo "       Set SNAPDAY_SIMULATOR to one shown by: xcrun simctl list devices available" >&2
    exit 66
  fi

  rm -rf "${RESULT_BUNDLE}"
  xcodebuild test \
    "${xcode_output_options[@]}" \
    "${common_options[@]}" \
    -destination "platform=iOS Simulator,name=${simulator_name},OS=${simulator_os}" \
    -resultBundlePath "${RESULT_BUNDLE}" \
    -testLanguage en \
    -testRegion US \
    -parallel-testing-enabled YES \
    "$@"
}

started_at="$(date +%s)"
echo "==> SnapDay validation: ${mode}"

case "${mode}" in
  quick)
    run_build Debug "$@"
    ;;
  test)
    run_tests "$@"
    ;;
  full)
    run_tests "$@"
    run_build Release "$@"
    ;;
esac

finished_at="$(date +%s)"
echo "==> Validation passed in $((finished_at - started_at))s"
