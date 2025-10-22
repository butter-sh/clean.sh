#!/bin/bash
# Test suite for clean.sh edge cases

# Setup before each test
setup() {
  TEST_ENV_DIR=$(create_test_env)
  cd "$TEST_ENV_DIR"
}

teardown() {
  cleanup_test_env
}

# Test: Nested heredocs
test_nested_heredocs() {
  setup

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

  output=$(cat "$temp")

  rm -f "$temp"

  outer_count=$(echo "$output" | grep -c "OUTER" || true)

  assert_true "[[ $outer_count -eq 2 ]]" "Should have both OUTER delimiters"
  assert_contains "$output" "Inner indented content" "Should preserve heredoc content"
  teardown
}

# Test: Regex patterns with special characters
test_regex_patterns() {
  setup

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

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" "=~" "Should preserve regex operator"
  assert_true "[[ \"\$output\" =~ \\^v ]]" "Should preserve caret in regex"
  assert_true "[[ \"\$output\" =~ \\[0-9\\] ]]" "Should preserve character class"
  teardown
}

# Test: Parameter expansion variations
test_parameter_expansions() {
  setup

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

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" '${VAR:-default}' "Should preserve default expansion"
  assert_contains "$output" '${#VAR}' "Should preserve length expansion"
  assert_contains "$output" '${VAR:0:5}' "Should preserve substring expansion"
  teardown
}

# Test: Command substitution variations
test_command_substitutions() {
  setup

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

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" '$(date' "Should preserve command substitution"
  assert_contains "$output" '$(echo' "Should preserve nested substitution"
  teardown
}

# Test: Arithmetic expansion variations
test_arithmetic_expansions() {
  setup

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

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" '$((a + b))' "Should preserve addition"
  assert_contains "$output" '$((a * b))' "Should preserve multiplication"
  teardown
}

# Test: Complex case statement
test_complex_case_statement() {
  setup

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

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" 'case' "Should preserve case statement"
  assert_contains "$output" 'esac' "Should preserve esac"
  assert_contains "$output" '-h|--help' "Should preserve pattern matching"
  teardown
}

# Test: Array operations
test_array_operations() {
  setup

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

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" 'declare -a' "Should preserve indexed array declaration"
  assert_contains "$output" 'declare -A' "Should preserve associative array declaration"
  assert_contains "$output" '${FILES[@]}' "Should preserve array expansion"
  teardown
}

# Test: Process substitution
test_process_substitution() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

compare_files() {
  diff <(sort file1.txt) <(sort file2.txt)
}
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" '<(sort file1.txt)' "Should preserve first process substitution"
  assert_contains "$output" '<(sort file2.txt)' "Should preserve second process substitution"
  teardown
}

# Test: Glob patterns
test_glob_patterns() {
  setup

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

  output=$(cat "$temp")

  rm -f "$temp"

  assert_contains "$output" '*.sh' "Should preserve star glob"
  assert_contains "$output" '**/*.txt' "Should preserve globstar"
  assert_contains "$output" 'file[0-9].txt' "Should preserve character class glob"
  teardown
}

# Test: Line continuation with backslash
test_line_continuation() {
  setup

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

  output=$(cat "$temp")

  rm -f "$temp"

  assert_true "[[ \"\$output\" == *\\\\* ]]" "Should preserve backslash line continuation"
  teardown
}

# Test: Shebang variations
test_shebang_variations() {
  setup

  local temp
  temp=$(mktemp)

  cat > "$temp" << 'EOF'
#!/usr/bin/env bash

echo "test"
EOF

  bash "$CLEAN_SH" format "$temp" >/dev/null 2>&1

  output=$(cat "$temp")

  rm -f "$temp"

  assert_true "[[ \"\$output\" =~ ^#!/usr/bin/env\\ bash ]]" "Should preserve shebang"
  teardown
}

# Run all tests
run_tests() {
  log_section "Edge Case Tests"

  test_nested_heredocs
  test_regex_patterns
  test_parameter_expansions
  test_command_substitutions
  test_arithmetic_expansions
  test_complex_case_statement
  test_array_operations
  test_process_substitution
  test_glob_patterns
  test_line_continuation
  test_shebang_variations
}

export -f run_tests
