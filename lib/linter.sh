#!/usr/bin/env bash

# linter.sh - Linting engine with rule validation
# Part of clean.sh

# Lint issue structure: level:rule:line_num:message
declare -a LINT_ISSUES=()

# Add a lint issue
add_issue() {
  local level="$1"    # error, warning, info
  local rule="$2"     # rule name
  local line_num="$3" # line number
  local message="$4"  # issue description

  LINT_ISSUES+=("$level:$rule:$line_num:$message")
}

# Clear lint issues
clear_issues() {
  LINT_ISSUES=()
}

# Check line length
check_line_length() {
  local line="$1"
  local line_num="$2"
  local max_length="${CONFIG[max_line_length]}"

  if [[ ${#line} -gt $max_length ]]; then
    local level="${SEVERITY[line_length]}"
    add_issue "$level" "line_length" "$line_num"  "Line exceeds maximum length of $max_length characters (current: ${#line})"
    return 1
  fi

  return 0
}

# Check bracket style
check_bracket_style() {
  local line="$1"
  local line_num="$2"

  if [[ "${CONFIG[use_double_brackets]}" != "true" ]]; then
    return 0
  fi

  # Skip protected contexts
  if is_protected_context "$line"; then
    return 0
  fi

  # Check for single brackets
  if [[ "$line" =~ [[:space:]]\[[[:space:]][^[] ]] && ! [[ "$line" =~ \[\[ ]]; then
    local level="${SEVERITY[bracket_style]}"
    add_issue "$level" "bracket_style" "$line_num"  "Use [[ ]] instead of [ ]"
    return 1
  fi

  # Check for test command (skip if inside quotes)
  # First check if the line has 'test' in a command context (not function names)
  if [[ "$line" =~ [[:space:]]test[[:space:]]+ ]] || [[ "$line" =~ ^test[[:space:]]+ ]]; then
    # Skip if it's inside quotes (simple check)
    if ! [[ "$line" =~ \"[^\"]*[[:space:]]test[[:space:]][^\"]*\" ]] && \
    ! [[ "$line" =~ \'[^\']*[[:space:]]test[[:space:]][^\']*\' ]]; then
      local level="${SEVERITY[deprecated_syntax]}"
      add_issue "$level" "deprecated_syntax" "$line_num"  "Use [[ ]] instead of 'test' command"
      return 1
    fi
  fi

  return 0
}

# Check spacing around operators
check_operator_spacing() {
  local line="$1"
  local line_num="$2"

  if [[ "${CONFIG[space_around_operators]}" != "true" ]]; then
    return 0
  fi

  # Skip protected contexts
  if is_protected_context "$line"; then
    return 0
  fi

  # Check for missing spaces around logical operators
  if [[ "$line" =~ \]\]\&\& ]] || [[ "$line" =~ \&\&\[\[ ]]; then
    local level="${SEVERITY[spacing_issues]}"
    add_issue "$level" "spacing_issues" "$line_num"  "Missing space around && operator"
    return 1
  fi

  if [[ "$line" =~ \]\]\|\| ]] || [[ "$line" =~ \|\|\[\[ ]]; then
    local level="${SEVERITY[spacing_issues]}"
    add_issue "$level" "spacing_issues" "$line_num"  "Missing space around || operator"
    return 1
  fi

  return 0
}

# Check variable quoting
check_variable_quoting() {
  local line="$1"
  local line_num="$2"

  if [[ "${CONFIG[quote_variables]}" != "true" ]]; then
    return 0
  fi

  # Skip protected contexts
  if is_protected_context "$line"; then
    return 0
  fi

  # Simple check for unquoted variables (heuristic)
  if [[ "$line" =~ =[[:space:]]*\$[a-zA-Z_] ]] && ! [[ "$line" =~ =[[:space:]]*[\"\'] ]]; then
    if ! is_in_string "$line" 0; then
      local level="${SEVERITY[missing_quotes]}"
      add_issue "info" "missing_quotes" "$line_num"  "Consider quoting variable assignments"
      return 1
    fi
  fi

  return 0
}

# Check indentation
check_indentation() {
  local line="$1"
  local line_num="$2"
  local expected_indent="$3"

  if [[ "${CONFIG[use_spaces]}" != "true" ]]; then
    return 0
  fi

  # Skip empty lines and comments
  if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
    return 0
  fi

  # Check for tabs
  if [[ "$line" =~ ^[[:space:]]*$'\t' ]]; then
    local level="${SEVERITY[spacing_issues]}"
    add_issue "$level" "spacing_issues" "$line_num"  "Use spaces instead of tabs for indentation"
    return 1
  fi

  return 0
}

# Lint a single line
lint_line() {
  local line="$1"
  local line_num="$2"
  local expected_indent="${3:-0}"

  # Skip empty lines and shebangs
  if [[ -z "$line" ]] || [[ "$line" =~ ^#! ]]; then
    return 0
  fi

  local has_issues=false

  # Run all checks
  check_line_length "$line" "$line_num" || has_issues=true
  check_bracket_style "$line" "$line_num" || has_issues=true
  check_operator_spacing "$line" "$line_num" || has_issues=true
  check_variable_quoting "$line" "$line_num" || has_issues=true
  check_indentation "$line" "$line_num" "$expected_indent" || has_issues=true

  [[ "$has_issues" == true ]] && return 1 || return 0
}

# Lint entire file
lint_file() {
  local file="$1"
  local verbose="${2:-false}"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  clear_issues

  if [[ "$verbose" == true ]]; then
    log_info "Linting: $file"
  fi

  echo "========================================"
  echo "Linting: $file"
  echo "========================================"
  echo

  local line_num=0
  local indent_level=0
  local in_heredoc=false
  local heredoc_delimiter=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))

    # Check for heredoc start
    if [[ "$in_heredoc" == false ]] && detect_heredoc_start "$line"; then
      in_heredoc=true
      heredoc_delimiter=$(extract_heredoc_delimiter "$line")
    fi

    # Check for heredoc end
    if [[ "$in_heredoc" == true ]] && is_heredoc_end "$line" "$heredoc_delimiter"; then
      in_heredoc=false
      heredoc_delimiter=""
      continue
    fi

    # Skip linting lines inside heredocs
    if [[ "$in_heredoc" == true ]]; then
      continue
    fi

    # Calculate expected indentation
    local trimmed="${line#"${line%%[![:space:]]*}"}"

    # Decrease indent before closing braces
    if [[ "$trimmed" =~ ^(}|fi|done|esac) ]]; then
      ((indent_level--)) || indent_level=0
    fi

    # Lint the line
    lint_line "$line" "$line_num" "$indent_level"

    # Increase indent after opening constructs
    if [[ "$trimmed" =~ (then|do|\{)$ ]] || [[ "$trimmed" =~ ^(function[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*$ ]]; then
      ((++indent_level))
    fi
  done < "$file"

  # Report issues
  local error_count=0
  local warning_count=0
  local info_count=0

  for issue in "${LINT_ISSUES[@]}"; do
    IFS=':' read -r level rule line_num message <<< "$issue"

    case "$level" in
      error)
        echo -e "${RED}[ERROR]${NC} Line $line_num: $message"
        ((error_count++))
        ;;
      warning)
        echo -e "${YELLOW}[WARN]${NC} Line $line_num: $message"
        ((warning_count++))
        ;;
      info)
        echo -e "${BLUE}[INFO]${NC} Line $line_num: $message"
        ((info_count++))
        ;;
    esac
  done

  echo
  echo "========================================"
  if [[ ${#LINT_ISSUES[@]} -eq 0 ]]; then
    echo -e "${GREEN}✓ No issues found${NC}"
  else
    echo -e "${BOLD}Summary:${NC}"
    [[ $error_count -gt 0 ]] && echo -e "  ${RED}Errors: $error_count${NC}"
    [[ $warning_count -gt 0 ]] && echo -e "  ${YELLOW}Warnings: $warning_count${NC}"
    [[ $info_count -gt 0 ]] && echo -e "  ${BLUE}Info: $info_count${NC}"
  fi
  echo "========================================"

  # Return error if there are errors
  [[ $error_count -gt 0 ]] && return 1 || return 0
}

# Check file without modifying (same as lint)
check_file() {
  lint_file "$@"
}
