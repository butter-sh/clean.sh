#!/usr/bin/env bash

# parser.sh - POSIX-compliant parser for bash/shell scripts
# Part of clean.sh
# Based on POSIX Shell EBNF Grammar

# Parse context tracking
declare -g PARSE_IN_STRING=false
declare -g PARSE_IN_COMMENT=false
declare -g PARSE_IN_REGEX=false
declare -g PARSE_IN_HEREDOC=false
declare -g PARSE_HEREDOC_DELIMITER=""
declare -g PARSE_STRING_CHAR=""

# Token types based on POSIX grammar
declare -A TOKEN_TYPES=(
[WORD]=1
[NUMBER]=2
[OPERATOR]=3
[REDIRECTION]=4
[KEYWORD]=5
[ASSIGNMENT]=6
[COMMENT]=7
[STRING]=8
[VARIABLE]=9
[EXPANSION]=10
[ARITHMETIC]=11
[SUBSTITUTION]=12
)

# POSIX shell keywords
declare -a BASH_KEYWORDS=(
"if" "then" "else" "elif" "fi"
"for" "do" "done" "in"
"while" "until"
"case" "esac"
"function"
)

# Reset parse context
reset_parse_context() {
  PARSE_IN_STRING=false
  PARSE_IN_COMMENT=false
  PARSE_IN_REGEX=false
  PARSE_IN_HEREDOC=false
  PARSE_HEREDOC_DELIMITER=""
  PARSE_STRING_CHAR=""
}

# Check if character position is inside a string
is_in_string() {
  local line="$1"
  local pos="$2"

  local before="${line:0:$pos}"
  local in_string=false
  local escape=false
  local quote_char=""

  for ((i=0; i<${#before}; i++)); do
    local char="${before:$i:1}"

    if [[ "$escape" == true ]]; then
      escape=false
      continue
    fi

    if [[ "$char" == "\\" ]]; then
      escape=true
      continue
    fi

    if [[ "$in_string" == false ]]; then
      if [[ "$char" == '"' ]] || [[ "$char" == "'" ]]; then
        in_string=true
        quote_char="$char"
      fi
      else
      if [[ "$char" == "$quote_char" ]]; then
        in_string=false
        quote_char=""
      fi
    fi
  done

  [[ "$in_string" == true ]]
}

# Check if line contains heredoc start
detect_heredoc_start() {
  local line="$1"

  # Match heredoc patterns: << or <<-
  if [[ "$line" =~ \<\<-?[[:space:]]*([A-Za-z_][A-Za-z0-9_]*|\'[^\']+\'|\"[^\"]+\"|[A-Z]+) ]]; then
    return 0
  fi

  return 1
}

# Extract heredoc delimiter from line
extract_heredoc_delimiter() {
  local line="$1"

  # Extract delimiter after << or <<-
  if [[ "$line" =~ \<\<-?[[:space:]]*([A-Za-z_][A-Za-z0-9_]*|\'[^\']+\'|\"[^\"]+\"|[A-Z]+) ]]; then
    local delim="${BASH_REMATCH[1]}"
    # Remove quotes from delimiter if present
    delim="${delim//[\'\"]/}"
    echo "$delim"
  fi
}

# Check if line is heredoc end delimiter
is_heredoc_end() {
  local line="$1"
  local delimiter="$2"

  [[ -n "$delimiter" ]] && [[ "$line" =~ ^[[:space:]]*"$delimiter"[[:space:]]*$ ]]
}

# Check if line contains parameter expansion (POSIX B.8)
is_parameter_expansion() {
  local line="$1"

  # Various forms: ${param}, ${param:-word}, ${param#word}, etc.
  if [[ "$line" =~ \$\{[^}]+\} ]]; then
    return 0
  fi

  return 1
}

# Check if line contains arithmetic expansion (POSIX B.10)
is_arithmetic_expansion() {
  local line="$1"

  # Arithmetic: $((expression))
  if [[ "$line" =~ \$\(\( ]]; then
    return 0
  fi

  return 1
}

# Check if line contains command substitution (POSIX B.9)
is_command_substitution() {
  local line="$1"

  # Modern: $(command) or Legacy: `command`
  if [[ "$line" =~ \$\( ]] || [[ "$line" =~ \` ]]; then
    return 0
  fi

  return 1
}

# Check if line contains regex pattern (bash extension)
is_regex_context() {
  local line="$1"

  # Check for regex context [[ ... =~ ... ]]
  if [[ "$line" =~ \[\[.*=~.*\]\] ]]; then
    return 0
  fi

  return 1
}

# Check if line contains brace expansion (bash extension, not POSIX)
is_brace_expansion() {
  local line="$1"

  # Brace expansion: {a,b,c} or {1..10}
  if [[ "$line" =~ \{[^}]*,[^}]*\} ]] || [[ "$line" =~ \{[0-9]+\.\.[0-9]+\} ]]; then
    return 0
  fi

  return 1
}

# Check if line contains glob pattern (POSIX B.19)
is_glob_pattern() {
  local line="$1"

  # Glob patterns: *, ?, [...]
  if [[ "$line" =~ \* ]] || [[ "$line" =~ \? ]] || [[ "$line" =~ \[[^]]+\] ]]; then
    return 0
  fi

  return 1
}

# Tokenize a line according to POSIX grammar
tokenize_line() {
  local line="$1"
  local tokens=()

  # Skip empty lines and comments
  if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
    echo "COMMENT:$line"
    return 0
  fi

  # Skip shebang
  if [[ "$line" =~ ^#! ]]; then
    echo "SHEBANG:$line"
    return 0
  fi

  # Simple tokenization
  local current_token=""
  local in_string=false
  local string_char=""

  for ((i=0; i<${#line}; i++)); do
    local char="${line:$i:1}"

    # Handle string contexts
    if [[ "$in_string" == false ]]; then
      if [[ "$char" == '"' ]] || [[ "$char" == "'" ]]; then
        in_string=true
        string_char="$char"
        current_token+="$char"
        continue
      fi
    else
      current_token+="$char"
      if [[ "$char" == "$string_char" ]]; then
        in_string=false
        string_char=""
      fi
      continue
    fi

    # Whitespace separates tokens
    if [[ "$char" =~ [[:space:]] ]]; then
      if [[ -n "$current_token" ]]; then
        tokens+=("$current_token")
        current_token=""
      fi
      continue
    fi

    current_token+="$char"
  done

  # Add final token
  if [[ -n "$current_token" ]]; then
    tokens+=("$current_token")
  fi

  # Output tokens
  for token in "${tokens[@]}"; do
    echo "TOKEN:$token"
  done
}

# Parse file and generate AST
parse_file() {
  local file="$1"
  local verbose="${2:-false}"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  if [[ "$verbose" == true ]]; then
    log_info "Parsing: $file"
  fi

  echo "=== AST for $file ==="
  echo

  local line_num=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))

    if [[ "$verbose" == true ]]; then
      echo "Line $line_num: $line"
    fi

    tokenize_line "$line"
    echo
  done < "$file"

  return 0
}

# Detect line context (used by linter and formatter)
get_line_context() {
  local line="$1"
  local context="normal"

  # Check for special contexts in priority order
  if [[ -z "$line" ]]; then
    context="empty"
  elif [[ "$line" =~ ^#! ]]; then
    context="shebang"
  elif [[ "$line" =~ ^[[:space:]]*# ]]; then
    context="comment"
  elif detect_heredoc_start "$line"; then
    context="heredoc_start"
  elif is_regex_context "$line"; then
    context="regex"
  elif is_arithmetic_expansion "$line"; then
    context="arithmetic"
  elif is_command_substitution "$line"; then
    context="substitution"
  elif is_parameter_expansion "$line"; then
    context="expansion"
  elif is_brace_expansion "$line"; then
    context="brace_expansion"
  fi

  echo "$context"
}

# Check if line should be protected from modification
is_protected_context() {
  local line="$1"
  local context
  context=$(get_line_context "$line")

  case "$context" in
    shebang|comment|heredoc_start|regex|arithmetic|substitution|expansion|brace_expansion)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}
