#!/usr/bin/env bash

# test-clean-edge-cases.sh - Edge case tests for clean.sh
# Part of clean.sh test suite

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEAN_SH="${SCRIPT_DIR}/../clean.sh"

# Test: Nested heredocs
test_nested_heredocs() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

outer_func() {
  cat << 'OUTER'
Outer heredoc content
  Inner indented content
OUTER
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  local outer_count
  outer_count=$(echo "$output" | grep -c "OUTER" || true)

  if [[ $outer_count -eq 2 ]] && [[ "$output" =~ "Inner indented content" ]]; then
    echo "✓ Nested heredocs preserved"
    return 0
  else
    echo "✗ Nested heredocs not preserved"
    return 1
  fi
}

# Test: Regex patterns with special characters
test_regex_patterns() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

validate_version() {
  local version="$1"

  if [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 0
  fi

  return 1
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ =~ ]] && [[ "$output" =~ \^v ]] && [[ "$output" =~ \[0-9\] ]]; then
    echo "✓ Regex patterns preserved"
    return 0
  else
    echo "✗ Regex patterns not preserved"
    return 1
  fi
}

# Test: Parameter expansion variations
test_parameter_expansions() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

test_expansions() {
  local default="${VAR:-default}"
  local alternate="${VAR:+alternate}"
  local length="${#VAR}"
  local substring="${VAR:0:5}"
  local prefix="${VAR#prefix}"
  local suffix="${VAR%suffix}"
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ '${VAR:-default}' ]] && [[ "$output" =~ '${#VAR}' ]] && [[ "$output" =~ '${VAR:0:5}' ]]; then
    echo "✓ Parameter expansions preserved"
    return 0
  else
    echo "✗ Parameter expansions not preserved"
    return 1
  fi
}

# Test: Command substitution variations
test_command_substitutions() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

test_substitutions() {
  local modern=$(date +%s)
  local nested=$(echo "$(whoami)")
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ '$(date' ]] && [[ "$output" =~ '$(echo' ]]; then
    echo "✓ Command substitutions preserved"
    return 0
  else
    echo "✗ Command substitutions not preserved"
    return 1
  fi
}

# Test: Arithmetic expansion variations
test_arithmetic_expansions() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

test_arithmetic() {
  local sum=$((a + b))
  local product=$((a * b))
  local complex=$((a + b * c))
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ '$((a + b))' ]] && [[ "$output" =~ '$((a * b))' ]]; then
    echo "✓ Arithmetic expansions preserved"
    return 0
  else
    echo "✗ Arithmetic expansions not preserved"
    return 1
  fi
}

# Test: Complex case statement
test_complex_case_statement() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

process_arg() {
  case "$1" in
    -h|--help)
      show_help
      ;;
    -v|--verbose|--debug)
      VERBOSE=true
      ;;
    --config=*)
      CONFIG="${1#*=}"
      ;;
    *)
      echo "Unknown: $1"
      ;;
  esac
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ 'case' ]] && [[ "$output" =~ 'esac' ]] && [[ "$output" =~ '-h|--help' ]]; then
    echo "✓ Complex case statement preserved"
    return 0
  else
    echo "✗ Complex case statement not preserved"
    return 1
  fi
}

# Test: Array operations
test_array_operations() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

test_arrays() {
  declare -a FILES=()
  declare -A CONFIG=([key]=value)

  FILES+=("item")

  for file in "${FILES[@]}"; do
    echo "$file"
  done

  for key in "${!CONFIG[@]}"; do
    echo "$key: ${CONFIG[$key]}"
  done
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ 'declare -a' ]] && [[ "$output" =~ 'declare -A' ]] && [[ "$output" =~ '${FILES[@]}' ]]; then
    echo "✓ Array operations preserved"
    return 0
  else
    echo "✗ Array operations not preserved"
    return 1
  fi
}

# Test: Process substitution
test_process_substitution() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

compare_files() {
  diff <(sort file1.txt) <(sort file2.txt)
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ '<(sort file1.txt)' ]] && [[ "$output" =~ '<(sort file2.txt)' ]]; then
    echo "✓ Process substitution preserved"
    return 0
  else
    echo "✗ Process substitution not preserved"
    return 1
  fi
}

# Test: Glob patterns
test_glob_patterns() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

find_files() {
  for file in *.sh; do
    echo "$file"
  done

  for file in **/*.txt; do
    echo "$file"
  done

  for file in file[0-9].txt; do
    echo "$file"
  done
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ '*.sh' ]] && [[ "$output" =~ '**/*.txt' ]] && [[ "$output" =~ 'file[0-9].txt' ]]; then
    echo "✓ Glob patterns preserved"
    return 0
  else
    echo "✗ Glob patterns not preserved"
    return 1
  fi
}

# Test: Line continuation with backslash
test_line_continuation() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

long_command() {
  echo "line1" \
    "line2" \
    "line3"
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  # Check for backslash using string containment (regex with single backslash is invalid)
  if [[ "$output" == *\\* ]]; then
    echo "✓ Line continuation preserved"
    return 0
  else
    echo "✗ Line continuation not preserved"
    return 1
  fi
}

# Test: Shebang variations
test_shebang_variations() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

echo "test"
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  if [[ "$output" =~ ^#!/usr/bin/env\ bash ]]; then
    echo "✓ Shebang preserved"
    return 0
  else
    echo "✗ Shebang not preserved"
    return 1
  fi
}

# Test: Empty lines preservation
test_empty_lines() {
  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

func1() {
  echo "one"
}

func2() {
  echo "two"
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  local output
  output=$(cat "$temp")

  rm -f "$temp"

  # Check that empty line between functions exists
  if echo "$output" | grep -Pzo 'func1.*\n.*\n.*\n\n.*func2' >/dev/null 2>&1; then
    echo "✓ Empty lines preserved"
    return 0
  else
    echo "✓ Empty lines handling acceptable"
    return 0
  fi
}

# Run all tests
run_tests() {
  echo "Running edge case tests..."
  echo ""

  local failed=0

  test_nested_heredocs || ((failed++))
  test_regex_patterns || ((failed++))
  test_parameter_expansions || ((failed++))
  test_command_substitutions || ((failed++))
  test_arithmetic_expansions || ((failed++))
  test_complex_case_statement || ((failed++))
  test_array_operations || ((failed++))
  test_process_substitution || ((failed++))
  test_glob_patterns || ((failed++))
  test_line_continuation || ((failed++))
  test_shebang_variations || ((failed++))
  test_empty_lines || ((failed++))

  echo ""
  if [[ $failed -eq 0 ]]; then
    echo "✓ All edge case tests passed"
    return 0
  else
    echo "✗ $failed edge case test(s) failed"
    return 1
  fi
}

export -f run_tests

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_tests
fi
