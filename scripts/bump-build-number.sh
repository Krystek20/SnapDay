#!/usr/bin/env bash

set -euo pipefail

PROJECT_FILE="SnapDay.xcodeproj/project.pbxproj"
DRY_RUN=0
REQUESTED_BUILD_NUMBER=""

usage() {
  cat <<'USAGE'
Usage:
  scripts/bump-build-number.sh [build-number]
  scripts/bump-build-number.sh --dry-run [build-number]

When build-number is omitted, the script increments the current SnapDay app
build number by 1. It updates app bundle targets:
SnapDay, ActivityWidget, and Notification Content.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -n "$REQUESTED_BUILD_NUMBER" ]]; then
        echo "error: pass at most one build number" >&2
        usage >&2
        exit 1
      fi
      REQUESTED_BUILD_NUMBER="$1"
      shift
      ;;
  esac
done

if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "error: $PROJECT_FILE not found. Run this script from the repository root." >&2
  exit 1
fi

if [[ -n "$REQUESTED_BUILD_NUMBER" && ! "$REQUESTED_BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "error: build number must be a positive integer" >&2
  exit 1
fi

ruby - "$PROJECT_FILE" "$DRY_RUN" "$REQUESTED_BUILD_NUMBER" <<'RUBY'
project_file = ARGV.fetch(0)
dry_run = ARGV.fetch(1) == "1"
requested_build_number = ARGV.fetch(2)

bundle_identifiers = [
  "com.mobilove.snapday",
  "com.mobilove.snapday.ActivityWidget",
  "com.mobilove.snapday.notification-content"
]

content = File.read(project_file)
target_blocks = content.scan(/(?m)^\t\t[A-F0-9]+ \/\* (?:Debug|Release) \*\/ = \{\n.*?^\t\t\};/)

current_build_numbers = target_blocks.map do |block|
  next unless bundle_identifiers.any? { |bundle_identifier| block.include?("PRODUCT_BUNDLE_IDENTIFIER = #{bundle_identifier};") || block.include?("PRODUCT_BUNDLE_IDENTIFIER = \"#{bundle_identifier}\";") }

  block[/CURRENT_PROJECT_VERSION = ([0-9]+);/, 1]&.to_i
end.compact

if current_build_numbers.empty?
  warn "error: no app target CURRENT_PROJECT_VERSION values found"
  exit 1
end

next_build_number = if requested_build_number.empty?
  current_build_numbers.max + 1
else
  requested_build_number.to_i
end

if next_build_number <= 0
  warn "error: build number must be greater than 0"
  exit 1
end

updated_content = content.gsub(/(?m)^\t\t[A-F0-9]+ \/\* (?:Debug|Release) \*\/ = \{\n.*?^\t\t\};/) do |block|
  is_app_target = bundle_identifiers.any? do |bundle_identifier|
    block.include?("PRODUCT_BUNDLE_IDENTIFIER = #{bundle_identifier};") ||
      block.include?("PRODUCT_BUNDLE_IDENTIFIER = \"#{bundle_identifier}\";")
  end

  next block unless is_app_target

  block.sub(/CURRENT_PROJECT_VERSION = [0-9]+;/, "CURRENT_PROJECT_VERSION = #{next_build_number};")
end

changed_lines = []
block_pattern = /(?m)^\t\t[A-F0-9]+ \/\* (?:Debug|Release) \*\/ = \{\n.*?^\t\t\};/
offset = 0

while (match = block_pattern.match(updated_content, offset))
  block = match[0]
  offset = match.end(0)

  is_app_target = bundle_identifiers.any? do |bundle_identifier|
    block.include?("PRODUCT_BUNDLE_IDENTIFIER = #{bundle_identifier};") ||
      block.include?("PRODUCT_BUNDLE_IDENTIFIER = \"#{bundle_identifier}\";")
  end

  next unless is_app_target

  block_start_line = updated_content[0...match.begin(0)].count("\n") + 1

  block.lines.each_with_index do |line, index|
    next unless line.include?("CURRENT_PROJECT_VERSION = #{next_build_number};")

    changed_lines << "#{block_start_line + index}: #{line.strip}"
  end
end

puts "Build number: #{current_build_numbers.uniq.sort.join(', ')} -> #{next_build_number}"
puts dry_run ? "Dry run: no files changed." : "Updated #{project_file}."
puts changed_lines.join("\n")

File.write(project_file, updated_content) unless dry_run
RUBY
