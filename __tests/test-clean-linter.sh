#!/usr/bin/env bash

# test-clean-linter.sh - Linter tests for clean.sh
# Part of clean.sh test suite

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEAN_SH="${SCRIPT_DIR}/../clean.sh"

# Test: Detect line length issues
test_line_length() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

# This is a very long line that exceeds the maximum line length configured in arty.yml which is set to 100 characters by default
EOF

  local output
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1 || true)

  rm -f "$temp"

  if [[ "$output" =~ "exceeds maximum length" ]]; then
    echo "✓ Line length issue detected"
    return 0
  else
    echo "✗ Line length issue not detected"
    return 1
  fi
}

# Test: Detect single bracket usage
test_single_brackets() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [ -f "file.txt" ]; then
  echo "found"
fi
EOF

  local output
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1 || true)

  rm -f "$temp"

  if [[ "$output" =~ "Use [[ ]] instead of [ ]" ]]; then
    echo "✓ Single bracket issue detected"
    return 0
  else
    echo "✗ Single bracket issue not detected"
    return 1
  fi
}

# Test: Detect test command usage
test_command_detection() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if test -f "file.txt"; then
  echo "found"
fi
EOF

  local output
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1 || true)

  rm -f "$temp"

  if [[ "$output" =~ "Use [[ ]] instead of 'test'" ]]; then
    echo "✓ Test command issue detected"
    return 0
  else
    echo "✗ Test command issue not detected"
    return 1
  fi
}

# Test: Detect missing spaces around operators
test_operator_spacing() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [[ -f "a" ]]&&[[ -f "b" ]]; then
  echo "found"
fi
EOF

  local output
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1 || true)

  rm -f "$temp"

  if [[ "$output" =~ "Missing space around" ]]; then
    echo "✓ Operator spacing issue detected"
    return 0
  else
    echo "✗ Operator spacing issue not detected"
    return 1
  fi
}

# Test: Detect tab indentation
test_tab_indentation() {
  local temp
  temp=$(mktemp)

  printf '#!/usr/bin/env bash\n\ntest_func() {\n\techo "test"\n}\n' > "$temp"

  local output
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1 || true)

  rm -f "$temp"

  if [[ "$output" =~ "Use spaces instead of tabs" ]]; then
    echo "✓ Tab indentation issue detected"
    return 0
  else
    echo "✗ Tab indentation issue not detected"
    return 1
  fi
}

# Test: Clean file passes linting
test_clean_file_passes() {
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

  local output
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)

  rm -f "$temp"

  if [[ "$output" =~ "No issues found" ]]; then
    echo "✓ Clean file passes linting"
    return 0
  else
    echo "✗ Clean file failed linting"
    echo "Output: $output"
    return 1
  fi
}

# Test: Multiple issues reported
test_multiple_issues() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

if [ -f "file.txt" ]&&[ -f "other.txt" ]; then
  echo "This is a very long line that exceeds the maximum line length configured in arty.yml which is set to 100 characters"
fi
EOF

  local output
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1 || true)

  rm -f "$temp"

  local issue_count
  issue_count=$(echo "$output" | grep -c "\[" || true)

  if [[ $issue_count -ge 2 ]]; then
    echo "✓ Multiple issues reported"
    return 0
  else
    echo "✗ Multiple issues not reported correctly"
    return 1
  fi
}

# Test: Comments are preserved
test_comments_preserved() {
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

  local output
  output=$(bash "$CLEAN_SH" lint "$temp" 2>&1)

  rm -f "$temp"

  if [[ "$output" =~ "No issues found" ]]; then
    echo "✓ Comments preserved during linting"
    return 0
  else
    echo "✗ Comments not preserved"
    return 1
  fi
}

# Run all tests
run_tests() {
  echo "Running linter tests..."
  echo ""

  local failed=0

  test_line_length || ((failed++))
  test_single_brackets || ((failed++))
  test_command_detection || ((failed++))
  test_operator_spacing || ((failed++))
  test_tab_indentation || ((failed++))
  test_clean_file_passes || ((failed++))
  test_multiple_issues || ((failed++))
  test_comments_preserved || ((failed++))

  echo ""
  if [[ $failed -eq 0 ]]; then
    echo "✓ All linter tests passed"
    return 0
  else
    echo "✗ $failed linter test(s) failed"
    return 1
  fi
}

export -f run_tests

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_tests
fi
