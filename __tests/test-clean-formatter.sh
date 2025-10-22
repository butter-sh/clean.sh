#!/usr/bin/env bash

# test-clean-formatter.sh - Formatter tests for clean.sh
# Part of clean.sh test suite

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEAN_SH="${SCRIPT_DIR}/../clean.sh"

# Test: Format single brackets to double brackets
test_format_brackets() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [ -f "file.txt" ]; then
  echo "found"
fi
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ "if [[ -f" ]]; then
    echo "✓ Brackets formatted correctly"
    return 0
  else
    echo "✗ Brackets not formatted"
    return 1
  fi
}

# Test: Format operator spacing
test_format_operator_spacing() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [[ -f "a" ]]&&[[ -f "b" ]]; then
  echo "found"
fi
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ "]] && [[" ]]; then
    echo "✓ Operator spacing formatted"
    return 0
  else
    echo "✗ Operator spacing not formatted"
    return 1
  fi
}

# Test: Format indentation
test_format_indentation() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

test_func() {
echo "test"
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ "  echo" ]]; then
    echo "✓ Indentation formatted"
    return 0
  else
    echo "✗ Indentation not formatted"
    return 1
  fi
}

# Test: Preserve heredocs exactly
test_preserve_heredocs() {
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

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ "HELP_EOF" ]] && [[ "$output" =~ "Usage: script.sh" ]]; then
    local eof_count
    eof_count=$(echo "$output" | grep -c "HELP_EOF" || true)

    if [[ $eof_count -eq 2 ]]; then
      echo "✓ Heredocs preserved correctly"
      return 0
    fi
  fi

  echo "✗ Heredocs not preserved"
  echo "Output: $output"
  return 1
}

# Test: Preserve strings
test_preserve_strings() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

VAR="test [ string ] with && operators"
echo "$VAR"
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ 'test [ string ] with && operators' ]]; then
    echo "✓ Strings preserved"
    return 0
  else
    echo "✗ Strings not preserved"
    return 1
  fi
}

# Test: Preserve comments
test_preserve_comments() {
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

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ "# Comment with [ brackets ]" ]] && [[ "$output" =~ "# Another comment with && operators" ]]; then
    echo "✓ Comments preserved"
    return 0
  else
    echo "✗ Comments not preserved"
    return 1
  fi
}

# Test: Preserve brace expansions
test_preserve_brace_expansion() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

for ext in {sh,bash,zsh}; do
  echo "$ext"
done
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ '{sh,bash,zsh}' ]]; then
    echo "✓ Brace expansion preserved"
    return 0
  else
    echo "✗ Brace expansion not preserved"
    echo "Output: $output"
    return 1
  fi
}

# Test: Idempotent formatting
test_idempotent_formatting() {
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

  local first_pass
  first_pass=$(cat "$temp")

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local second_pass
  second_pass=$(cat "$temp")

  rm -f "$temp"

  if [[ "$first_pass" == "$second_pass" ]]; then
    echo "✓ Formatting is idempotent"
    return 0
  else
    echo "✗ Formatting is not idempotent"
    return 1
  fi
}

# Test: Format test command to double brackets
test_format_test_command() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if test -f "file.txt"; then
  echo "found"
fi
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ "if [[ -f" ]]; then
    echo "✓ Test command formatted"
    return 0
  else
    echo "✗ Test command not formatted"
    return 1
  fi
}

# Run all tests
run_tests() {
  echo "Running formatter tests..."
  echo ""

  local failed=0

  test_format_brackets || ((failed++))
  test_format_operator_spacing || ((failed++))
  test_format_indentation || ((failed++))
  test_preserve_heredocs || ((failed++))
  test_preserve_strings || ((failed++))
  test_preserve_comments || ((failed++))
  test_preserve_brace_expansion || ((failed++))
  test_idempotent_formatting || ((failed++))
  test_format_test_command || ((failed++))

  echo ""
  if [[ $failed -eq 0 ]]; then
    echo "✓ All formatter tests passed"
    return 0
  else
    echo "✗ $failed formatter test(s) failed"
    return 1
  fi
}

export -f run_tests

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_tests
fi
