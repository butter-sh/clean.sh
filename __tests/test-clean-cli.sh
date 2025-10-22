#!/usr/bin/env bash

# test-clean-cli.sh - CLI tests for clean.sh
# Part of clean.sh test suite

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEAN_SH="${SCRIPT_DIR}/../clean.sh"

# Test: Show help message
test_show_help() {
  local output
  output=$(bash "$CLEAN_SH" help 2>&1)

  if [[ "$output" =~ "POSIX-compliant Bash Linter" ]]; then
    echo "✓ Help message displayed"
    return 0
  else
    echo "✗ Help message not displayed correctly"
    return 1
  fi
}

# Test: Show help with --help flag
test_show_help_flag() {
  local output
  output=$(bash "$CLEAN_SH" --help 2>&1)

  if [[ "$output" =~ "USAGE:" ]]; then
    echo "✓ Help flag works"
    return 0
  else
    echo "✗ Help flag failed"
    return 1
  fi
}

# Test: No command specified
test_no_command() {
  local output
  output=$(bash "$CLEAN_SH" 2>&1 || true)

  if [[ "$output" =~ "No command specified" ]]; then
    echo "✓ No command error displayed"
    return 0
  else
    echo "✗ No command error not displayed"
    return 1
  fi
}

# Test: No files specified
test_no_files() {
  local output
  output=$(bash "$CLEAN_SH" lint 2>&1 || true)

  if [[ "$output" =~ "No files specified" ]]; then
    echo "✓ No files error displayed"
    return 0
  else
    echo "✗ No files error not displayed"
    return 1
  fi
}

# Test: File not found
test_file_not_found() {
  local output
  output=$(bash "$CLEAN_SH" lint /nonexistent/file.sh 2>&1 || true)

  if [[ "$output" =~ "File not found" ]]; then
    echo "✓ File not found error displayed"
    return 0
  else
    echo "✗ File not found error not displayed"
    return 1
  fi
}

# Test: Lint command on clean file
test_lint_clean_file() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

# Test function
test_func() {
  local var="value"
  echo "$var"
}
EOF

  local output
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)

  rm -f "$temp"

  if [[ "$output" =~ "No issues found" ]]; then
    echo "✓ Lint passed on clean file"
    return 0
  else
    echo "✗ Lint failed on clean file"
    echo "Output: $output"
    return 1
  fi
}

# Test: Format command creates valid output
test_format_command() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash
test_func(){
echo "test"
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ "test_func()" ]] && [[ "$output" =~ "  echo" ]]; then
    echo "✓ Format command works"
    return 0
  else
    echo "✗ Format command failed"
    return 1
  fi
}

# Test: Check command (same as lint)
test_check_command() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

test_func() {
  echo "test"
}
EOF

  local output
  output=$(bash "$CLEAN_SH" check "$temp" 2>&1)

  rm -f "$temp"

  if [[ "$output" =~ "Linting:" ]]; then
    echo "✓ Check command works"
    return 0
  else
    echo "✗ Check command failed"
    return 1
  fi
}

# Test: Parse command
test_parse_command() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash
echo "test"
EOF

  local output
  output=$(bash "$CLEAN_SH" parse "$temp" 2>&1)

  rm -f "$temp"

  if [[ "$output" =~ "AST for" ]]; then
    echo "✓ Parse command works"
    return 0
  else
    echo "✗ Parse command failed"
    return 1
  fi
}

# Run all tests
run_tests() {
  echo "Running CLI tests..."
  echo ""

  local failed=0

  test_show_help || ((failed++))
  test_show_help_flag || ((failed++))
  test_no_command || ((failed++))
  test_no_files || ((failed++))
  test_file_not_found || ((failed++))
  test_lint_clean_file || ((failed++))
  test_format_command || ((failed++))
  test_check_command || ((failed++))
  test_parse_command || ((failed++))

  echo ""
  if [[ $failed -eq 0 ]]; then
    echo "✓ All CLI tests passed"
    return 0
  else
    echo "✗ $failed CLI test(s) failed"
    return 1
  fi
}

export -f run_tests

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_tests
fi
