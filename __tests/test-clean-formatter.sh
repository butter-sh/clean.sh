#!/bin/bash
# Test suite for clean.sh formatter functionality

# Setup before each test
setup() {
  TEST_ENV_DIR=$(create_test_env)
  cd "$TEST_ENV_DIR"
}

teardown() {
  cleanup_test_env
}

# Test: Format single brackets to double brackets
test_format_brackets() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [ -f "file.txt" ]; then
  echo "found"
fi
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" "if [[ -f" "Should convert to double brackets"
  teardown
}

# Test: Format operator spacing
test_format_operator_spacing() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [[ -f "a" ]]&&[[ -f "b" ]]; then
  echo "found"
fi
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" "]] && [[" "Should add spaces around operator"
  teardown
}

# Test: Format indentation
test_format_indentation() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

test_func() {
echo "test"
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" "  echo" "Should indent function body"
  teardown
}

# Test: Preserve heredocs exactly
test_preserve_heredocs() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

show_help() {
  cat << 'HELP_EOF'
Usage: script.sh [options]

Options:
  -h, --help    Show help
  -v            Verbose mode
HELP_EOF
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  heredoc_count=$(echo "$output" | grep -c "HELP_EOF" || true)

  assert_contains "$output" "Usage: script.sh" "Should preserve heredoc content"
  assert_true "[[ $heredoc_count -eq 2 ]]" "Should have both heredoc delimiters"
  teardown
}

# Test: Preserve strings
test_preserve_strings() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

VAR="test [ string ] with && operators"
echo "$VAR"
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" 'test [ string ] with && operators' "Should preserve string content"
  teardown
}

# Test: Preserve comments
test_preserve_comments() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

# Comment with [ brackets ] and test command
# Another comment with && operators
test_func() {
  echo "test"
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" "# Comment with [ brackets ]" "Should preserve comment content"
  assert_contains "$output" "# Another comment with && operators" "Should preserve operator in comment"
  teardown
}

# Test: Preserve brace expansions
test_preserve_brace_expansion() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

for ext in {sh,bash,zsh}; do
  echo "$ext"
done
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" '{sh,bash,zsh}' "Should preserve brace expansion"
  teardown
}

# Test: Idempotent formatting
test_idempotent_formatting() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

test_func() {
  local var="value"

  if [[ -n "$var" ]]; then
    echo "$var"
  fi
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

first_pass=$(cat "$temp")

bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

second_pass=$(cat "$temp")

rm -f "$temp"

assert_equals "$first_pass" "$second_pass" "Formatting should be idempotent"
teardown
}

# Test: Format test command to double brackets
test_format_test_command() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if test -f "file.txt"; then
  echo "found"
fi
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" "if [[ -f" "Should convert test command to double brackets"
  teardown
}

# Run all tests
run_tests() {
  log_section "Formatter Tests"

  test_format_brackets
  test_format_operator_spacing
  test_format_indentation
  test_preserve_heredocs
  test_preserve_strings
  test_preserve_comments
  test_preserve_brace_expansion
  test_idempotent_formatting
  test_format_test_command
}

export -f run_tests
