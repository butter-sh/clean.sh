#!/bin/bash
# Test suite for clean.sh linter functionality

# Setup before each test
setup() {
  TEST_ENV_DIR=$(create_test_env)
  cd "$TEST_ENV_DIR"
}

teardown() {
  cleanup_test_env
}

# Test: Detect line length issues
test_line_length() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

# This is a very long line that exceeds the maximum line length configured in arty.yml which is set to 100 characters by default
EOF

  set +e
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)
  set -e

  rm -f "$temp"

  assert_contains "$output" "exceeds maximum length" "Should detect line length issue"
  # Line length is a warning, not an error, so exit code is 0
  teardown
}

# Test: Detect single bracket usage
test_single_brackets() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [ -f "file.txt" ]; then
  echo "found"
fi
EOF

  set +e
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)
  set -e

  rm -f "$temp"

  assert_contains "$output" "Use [[ ]] instead of [ ]" "Should detect single brackets"
  teardown
}

# Test: Detect test command usage
test_command_detection() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if test -f "file.txt"; then
  echo "found"
fi
EOF

  set +e
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)
  set -e

  rm -f "$temp"

  assert_contains "$output" "Use [[ ]] instead of 'test'" "Should detect test command"
  teardown
}

# Test: Detect missing spaces around operators
test_operator_spacing() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [[ -f "a" ]]&&[[ -f "b" ]]; then
  echo "found"
fi
EOF

  set +e
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)
  set -e

  rm -f "$temp"

  assert_contains "$output" "Missing space around" "Should detect spacing issues"
  teardown
}

# Test: Detect tab indentation
test_tab_indentation() {
  setup

  local temp
  temp=$(mktemp)

  printf '#!/usr/bin/env bash\n\ntest_func() {\n\techo "test"\n}\n' > "$temp"

  set +e
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)
  set -e

  rm -f "$temp"

  assert_contains "$output" "Use spaces instead of tabs" "Should detect tab indentation"
  teardown
}

# Test: Clean file passes linting
test_clean_file_passes() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

# Clean test function
test_func() {
  local var="value"

  if [[ -n "$var" ]]; then
    echo "$var"
    return 0
  fi

  return 1
}
EOF

  set +e
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)
  exit_code=$?
  set -e

  rm -f "$temp"

  assert_contains "$output" "No issues found" "Should pass linting"
  assert_true "[[ $exit_code -eq 0 ]]" "Should exit with success code"
  teardown
}

# Test: Multiple issues reported
test_multiple_issues() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [ -f "file.txt" ]&&[ -f "other.txt" ]; then
  echo "This is a very long line that exceeds the maximum line length configured in arty.yml which is set to 100 characters"
fi
EOF

  set +e
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)
  set -e

  rm -f "$temp"

  # Should detect multiple issues
  assert_contains "$output" "[" "Should show issues"
  teardown
}

# Test: Comments are preserved during linting
test_comments_preserved() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

# This is a comment with [ brackets ] and test command
# It should not trigger linting errors
test_func() {
  echo "test"
}
EOF

  set +e
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)
  exit_code=$?
  set -e

  rm -f "$temp"

  assert_contains "$output" "No issues found" "Comments should not trigger errors"
  assert_true "[[ $exit_code -eq 0 ]]" "Should exit with success code"
  teardown
}

# Test: Linter shows summary
test_linter_shows_summary() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [ -f "test" ]; then
  echo "test"
fi
EOF

  set +e
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)
  set -e

  rm -f "$temp"

  assert_contains "$output" "Summary:" "Should show summary"
  teardown
}

# Run all tests
run_tests() {
  log_section "Linter Tests"

  test_line_length
  test_single_brackets
  test_command_detection
  test_operator_spacing
  test_tab_indentation
  test_clean_file_passes
  test_multiple_issues
  test_comments_preserved
  test_linter_shows_summary
}

export -f run_tests
