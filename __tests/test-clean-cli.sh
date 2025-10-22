#!/bin/bash
# Test suite for clean.sh CLI interface and commands

# Setup before each test
setup() {
  TEST_ENV_DIR=$(create_test_env)
  cd "$TEST_ENV_DIR"
}

teardown() {
  cleanup_test_env
}

# Test: Show help message
test_show_help() {
  setup

  output=$(bash "$CLEAN_SH" help 2>&1)

  assert_contains "$output" "POSIX-compliant Bash Linter" "Should show description"
  assert_contains "$output" "COMMANDS:" "Should show commands section"
  teardown
}

# Test: Show help with --help flag
test_show_help_flag() {
  setup

  output=$(bash "$CLEAN_SH" --help 2>&1)

  assert_contains "$output" "USAGE:" "Should show usage"
  teardown
}

# Test: Show help with -h flag
test_show_help_short_flag() {
  setup

  output=$(bash "$CLEAN_SH" -h 2>&1)

  assert_contains "$output" "USAGE:" "Should show usage"
  teardown
}

# Test: No command specified
test_no_command() {
  setup

  set +e
  output=$(bash "$CLEAN_SH" 2>&1)
  exit_code=$?
  set -e

  assert_contains "$output" "No command specified" "Should show error message"
  assert_true "[[ $exit_code -ne 0 ]]" "Should exit with non-zero code"
  teardown
}

# Test: No files specified
test_no_files() {
  setup

  set +e
  output=$(bash "$CLEAN_SH" lint 2>&1)
  exit_code=$?
  set -e

  assert_contains "$output" "No files specified" "Should show error message"
  assert_true "[[ $exit_code -ne 0 ]]" "Should exit with non-zero code"
  teardown
}

# Test: File not found
test_file_not_found() {
  setup

  set +e
  output=$(bash "$CLEAN_SH" lint /nonexistent/file.sh 2>&1)
  exit_code=$?
  set -e

  assert_contains "$output" "File not found" "Should show error message"
  assert_true "[[ $exit_code -ne 0 ]]" "Should exit with non-zero code"
  teardown
}

# Test: Lint command on clean file
test_lint_clean_file() {
  setup

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

  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)

  rm -f "$temp"

  assert_contains "$output" "No issues found" "Should pass linting"
  teardown
}

# Test: Format command creates valid output
test_format_command() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash
test_func(){
echo "test"
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" "test_func()" "Should format function declaration"
  assert_contains "$output" "  echo" "Should indent function body"
  teardown
}

# Test: Check command (same as lint)
test_check_command() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

test_func() {
  echo "test"
}
EOF

  output=$(bash "$CLEAN_SH" check "$temp" 2>&1)

  rm -f "$temp"

  assert_contains "$output" "Linting:" "Should run linter"
  teardown
}

# Test: Parse command
test_parse_command() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash
echo "test"
EOF

  output=$(bash "$CLEAN_SH" parse "$temp" 2>&1)

  rm -f "$temp"

  assert_contains "$output" "AST for" "Should show AST output"
  teardown
}

# Test: Usage shows all major commands
test_usage_shows_commands() {
  setup

  output=$(bash "$CLEAN_SH" help 2>&1)

  assert_contains "$output" "lint" "Should show lint command"
  assert_contains "$output" "format" "Should show format command"
  assert_contains "$output" "check" "Should show check command"
  assert_contains "$output" "parse" "Should show parse command"
  teardown
}

# Test: Usage shows configuration section
test_usage_shows_configuration() {
  setup

  output=$(bash "$CLEAN_SH" help 2>&1)

  assert_contains "$output" "CONFIGURATION:" "Should show configuration section"
  assert_contains "$output" "arty.yml" "Should mention configuration file"
  teardown
}

# Test: Usage shows examples
test_usage_shows_examples() {
  setup

  output=$(bash "$CLEAN_SH" help 2>&1)

  assert_contains "$output" "EXAMPLES:" "Should show examples section"
  teardown
}

# Run all tests
run_tests() {
  log_section "CLI Tests"

  test_show_help
  test_show_help_flag
  test_show_help_short_flag
  test_no_command
  test_no_files
  test_file_not_found
  test_lint_clean_file
  test_format_command
  test_check_command
  test_parse_command
  test_usage_shows_commands
  test_usage_shows_configuration
  test_usage_shows_examples
}

export -f run_tests
