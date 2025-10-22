#!/usr/bin/env bash

# formatter.sh - Formatting engine with heredoc-safe rule application
# Part of clean.sh

# Check if line contains quoted strings with special patterns
# Returns 0 (true) if brackets or operators are INSIDE quoted strings
has_quoted_special_chars() {
  local line="$1"
  local in_quote=false
  local quote_char=""
  local i
  local char
  local prev_char=""

  # Scan character by character
  for ((i=0; i<${#line}; i++)); do
    char="${line:$i:1}"

    # Handle quote toggling (skip escaped quotes)
    if [[ "$prev_char" != "\\" ]]; then
      if [[ "$char" == '"' ]] || [[ "$char" == "'" ]]; then
        if [[ "$in_quote" == false ]]; then
          in_quote=true
          quote_char="$char"
          elif [[ "$char" == "$quote_char" ]]; then
            in_quote=false
            quote_char=""
          fi
        fi
      fi

    # If we're inside a quote, check for special characters
      if [[ "$in_quote" == true ]]; then
        local next_char="${line:$((i+1)):1}"
        if [[ "$char" == "[" ]] || [[ "$char$next_char" == "&&" ]] || [[ "$char$next_char" == "||" ]]; then
          return 0
        fi
      fi

      prev_char="$char"
    done

    return 1
  }

# Format bracket style
fix_brackets() {
  local line="$1"

  if [[ "${CONFIG[use_double_brackets]}" != "true" ]]; then
    echo "$line"
    return 0
  fi

  # Skip protected contexts
  if is_protected_context "$line"; then
    echo "$line"
    return 0
  fi

  # Skip lines with special characters in quoted strings
  if has_quoted_special_chars "$line"; then
    echo "$line"
    return 0
  fi

  local fixed="$line"

  # Fix 'test' command to [[ ]]
  if [[ "$fixed" =~ [[:space:]]test[[:space:]]+ ]]; then
  fixed=$(echo "$fixed" | sed 's/\btest \(.*\); *\(then\|do\)/[[ \1 ]]; \2/g')
fi

  # Fix single brackets [ to [[
if [[ "$fixed" =~ \[[[:space:]][^[] ]] && ! [[ "$fixed" =~ \[\[ ]]; then
fixed=$(echo "$fixed" | sed 's/\[ /[[ /g; s/ \];/ ]];/g')
fi

  # Fix mixed brackets [[ ... ] to [[ ... ]]
if [[ "$fixed" =~ \[\[ ]] && [[ "$fixed" =~ \][[:space:]]*(&&|\|\||;|$) ]]; then
    # Has [[ but might have single ] closing - fix it
fixed=$(echo "$fixed" | sed 's/\(\[\[[^]]*\)\][[:space:]]*\(&&\|||\)/\1]] \2/g')
fi

echo "$fixed"
}

# Fix operator spacing
fix_operator_spacing() {
  local line="$1"

  if [[ "${CONFIG[space_around_operators]}" != "true" ]]; then
    echo "$line"
    return 0
  fi

  # Skip protected contexts
  if is_protected_context "$line"; then
    echo "$line"
    return 0
  fi

  # Skip lines with special characters in quoted strings
  if has_quoted_special_chars "$line"; then
    echo "$line"
    return 0
  fi

  local fixed="$line"

  # Fix logical operators && and ||
  if ! [[ "$fixed" =~ =~ ]]; then
    # Fix && operator: remove any existing spaces, then add proper spacing
  fixed=$(echo "$fixed" | sed 's/\]\][[:space:]]*\&\&[[:space:]]*/]] \&\& /g')
fixed=$(echo "$fixed" | sed 's/\&\&[[:space:]]*\[\[/\&\& [[/g')
    # Fix || operator similarly
fixed=$(echo "$fixed" | sed 's/\]\][[:space:]]*||[[:space:]]*/]] || /g')
fixed=$(echo "$fixed" | sed 's/||[[:space:]]*\[\[/|| [[/g')
fi

  # Fix space before braces if configured
if [[ "${CONFIG[space_before_brace]}" == "true" ]]; then
fixed=$(echo "$fixed" | sed 's/){/) {/g; s/then{/then {/g; s/do{/do {/g')
fi

  # Fix space after comma if configured (but not in brace expansions)
if [[ "${CONFIG[space_after_comma]}" == "true" ]]; then
    # Use parser function for POSIX-compliant detection
  if ! is_brace_expansion "$fixed"; then
  fixed=$(echo "$fixed" | sed 's/,\([^ ]\)/, \1/g')
fi
fi

echo "$fixed"
}

# Wrap long lines intelligently
wrap_long_line() {
  local line="$1"
  local max_len="${CONFIG[max_line_length]}"
  local indent="$2"

  # Don't wrap if line is short enough
  if [[ ${#line} -le $max_len ]]; then
    echo "$line"
    return 0
  fi

  # Don't wrap protected contexts
  if is_protected_context "$line"; then
    echo "$line"
    return 0
  fi

  # Don't wrap lines with operators/pipes inside quoted strings
  if has_quoted_special_chars "$line"; then
    echo "$line"
    return 0
  fi

  # Try to wrap at pipe operators - DISABLED to avoid creating problematic patterns
  # The pattern `... \` + `  | ...` can look like duplicate pipes and cause issues
  # For now, we'll let long lines with pipes remain as-is
  # TODO: Implement smarter wrapping that doesn't create ambiguous patterns
  if false && [[ "$line" =~ \| ]] && ! [[ "$line" =~ =~ ]]; then
    local result=""
    local current=""
    local first=true

    IFS='|' read -ra parts <<< "$line"

    for part in "${parts[@]}"; do
      # Trim leading/trailing whitespace
      part="${part#"${part%%[![:space:]]*}"}"
      part="${part%"${part##*[![:space:]]}"}"

      if $first; then
        current="$part"
        first=false
      else
        if [[ $((${#current} + ${#part} + 3)) -gt $max_len ]]; then
          # Add to result with line continuation
          if [[ -n "$result" ]]; then
            result="${result}"$'\n'"${current} \\"
          else
            result="${current} \\"
          fi
          current="${indent}  | ${part}"
        else
          current="${current} | ${part}"
        fi
      fi
    done

    # Output accumulated result plus final current segment
    if [[ -n "$result" ]]; then
      echo "$result"
      echo "$current"
    else
      echo "$current"
    fi
    return 0
  fi

  # Try to wrap at logical operators
  if [[ "$line" =~ \&\& ]] && ! [[ "$line" =~ =~ ]]; then
    if [[ "$line" =~ ^(.+[[:space:]])(\&\&)([[:space:]].+)$ ]]; then
      local part1="${BASH_REMATCH[1]}"
      local op="${BASH_REMATCH[2]}"
      local part2="${BASH_REMATCH[3]}"

      echo "${part1}${op} \\"
      echo "${indent}  ${part2}"
      return 0
    fi
  fi

  if [[ "$line" =~ \|\| ]] && ! [[ "$line" =~ =~ ]]; then
    if [[ "$line" =~ ^(.+[[:space:]])(\|\|)([[:space:]].+)$ ]]; then
      local part1="${BASH_REMATCH[1]}"
      local op="${BASH_REMATCH[2]}"
      local part2="${BASH_REMATCH[3]}"

      echo "${part1}${op} \\"
      echo "${indent}  ${part2}"
      return 0
    fi
  fi

  # Default: return as-is (better than corrupting)
  echo "$line"
}

# Fix indentation with heredoc awareness
fix_indentation() {
  local line="$1"
  local indent_level="$2"
  local in_heredoc="$3"

  if [[ "${CONFIG[use_spaces]}" != "true" ]]; then
    echo "$line"
    return 0
  fi

  # Skip empty lines, shebangs, and comments
  if [[ -z "$line" ]] || [[ "$line" =~ ^#! ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
    echo "$line"
    return 0
  fi

  # CRITICAL: If inside heredoc, preserve original line exactly
  if [[ "$in_heredoc" == "true" ]]; then
    echo "$line"
    return 0
  fi

  # Calculate indent
  local indent_size="${CONFIG[indent_size]}"
  local spaces=$((indent_level * indent_size))
  local indent=""

  for ((i=0; i<spaces; i++)); do
    indent+=" "
  done

  # Remove existing indentation and apply new
  local trimmed="${line#"${line%%[![:space:]]*}"}"

  # Don't modify if line has no content
  if [[ -z "$trimmed" ]]; then
    echo "$line"
    return 0
  fi

  echo "${indent}${trimmed}"
}

# Format a single line
format_line() {
  local line="$1"
  local indent_level="${2:-0}"
  local in_heredoc="${3:-false}"

  # Skip empty lines and shebangs
  if [[ -z "$line" ]] || [[ "$line" =~ ^#! ]]; then
    echo "$line"
    return 0
  fi

  # Skip comments
  if [[ "$line" =~ ^[[:space:]]*# ]]; then
    echo "$line"
    return 0
  fi

  # If inside heredoc, preserve line exactly
  if [[ "$in_heredoc" == "true" ]]; then
    echo "$line"
    return 0
  fi

  local fixed="$line"

  # Apply fixes in order
  fixed=$(fix_brackets "$fixed")
  fixed=$(fix_operator_spacing "$fixed")

  # Calculate indent string for wrapping
  local indent_size="${CONFIG[indent_size]}"
  local spaces=$((indent_level * indent_size))
  local indent=""
  for ((i=0; i<spaces; i++)); do
    indent+=" "
  done

  # Apply line wrapping if needed
  fixed=$(wrap_long_line "$fixed" "$indent")

  # Apply indentation (only if not already wrapped)
  if [[ "$(echo "$fixed" | wc -l)" -eq 1 ]]; then
    fixed=$(fix_indentation "$fixed" "$indent_level" "$in_heredoc")
  fi

  echo "$fixed"
}

# Format entire file with heredoc state tracking
format_file() {
  local file="$1"
  local verbose="${2:-false}"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  if [[ "$verbose" == true ]]; then
    log_info "Formatting: $file"
  fi

  echo "========================================"
  echo "Formatting: $file"
  echo "========================================"
  echo

  local temp
  temp=$(mktemp) || {
    log_error "Cannot create temp file"
    return 1
  }

  local line_num=0
  local fixes=0
  local indent_level=0
  local in_heredoc=false
  local heredoc_delimiter=""
  local continued_line=""
  local in_continuation=false

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
      # Output heredoc end marker as-is
      printf "%s\n" "$line" >> "$temp"
      continue
    fi

    # Handle line continuations - only join to fix duplicate operators
    if [[ "$in_heredoc" == false ]] && [[ "$line" =~ \\[[:space:]]*$ ]]; then
      # Line ends with backslash - peek at next line to check for issues
      if [[ "$in_continuation" == false ]]; then
        continued_line="${line}"
        in_continuation=true
      else
        # Accumulate continuation lines
        continued_line="${continued_line}"$'\n'"${line}"
      fi
      continue
    elif [[ "$in_continuation" == true ]]; then
      # This line completes the continuation - check for duplicate operators
      local trimmed_line="${line#"${line%%[![:space:]]*}"}"
      local prev_line_content="${continued_line##*$'\n'}"
      prev_line_content="${prev_line_content%\\*}"

      # Check if we have duplicate pipe operators
      # Case 1: Last continuation line ends with | and current line starts with |
      # Case 2: Current line has multiple consecutive pipes |  |
      if ([[ "$prev_line_content" =~ \|[[:space:]]*$ ]] && [[ "$trimmed_line" =~ ^\|[[:space:]] ]]) || \
         [[ "$trimmed_line" =~ \|[[:space:]]+\| ]]; then
        # Duplicate pipe - join and fix
        local joined=""
        while IFS= read -r cont_line; do
          cont_line="${cont_line%\\*}"
          cont_line="${cont_line#"${cont_line%%[![:space:]]*}"}"
          if [[ -n "$joined" ]]; then
            joined="${joined} ${cont_line}"
          else
            joined="${cont_line}"
          fi
        done <<< "$continued_line"

        # Add final line
        joined="${joined} ${trimmed_line}"

        # Remove duplicate pipe
        joined=$(echo "$joined" | sed 's/|[[:space:]]*|[[:space:]]*/| /g')

        line="$joined"
      else
        # No duplicate - process continuation lines individually
        while IFS= read -r cont_line; do
          local fixed_cont
          fixed_cont=$(format_line "$cont_line" "$indent_level" "$in_heredoc")
          printf "%s\n" "$fixed_cont" >> "$temp"

          # Track indent changes
          local trimmed_cont="${cont_line#"${cont_line%%[![:space:]]*}"}"
          if [[ "$in_heredoc" == false ]] && [[ "$trimmed_cont" =~ ^(}|fi|done|esac) ]]; then
            ((indent_level--)) || indent_level=0
          fi
          if [[ "$in_heredoc" == false ]] && \
             ([[ "$trimmed_cont" =~ (then|do|\{)$ ]] || \
              [[ "$trimmed_cont" =~ ^(function[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*$ ]]); then
            ((++indent_level))
          fi
        done <<< "$continued_line"

        # Process the final line normally (without backslash)
        line="$line"
      fi

      in_continuation=false
      continued_line=""
    fi

    # Calculate current indentation level
    local trimmed="${line#"${line%%[![:space:]]*}"}"

    # Decrease indent before closing braces (only if not in heredoc)
    if [[ "$in_heredoc" == false ]] && [[ "$trimmed" =~ ^(}|fi|done|esac) ]]; then
      ((indent_level--)) || indent_level=0
    fi

    # Format the line
    local fixed
    fixed=$(format_line "$line" "$indent_level" "$in_heredoc")

    # Increase indent after opening constructs (only if not in heredoc)
    if [[ "$in_heredoc" == false ]] && \
       ([[ "$trimmed" =~ (then|do|\{)$ ]] || \
        [[ "$trimmed" =~ ^(function[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*$ ]]); then
      ((++indent_level))
    fi

    # Count lines for comparison
    local fixed_line_count
    fixed_line_count=$(echo "$fixed" | wc -l)

    # Show what changed
    if [[ "$line" != "$fixed" ]] || [[ $fixed_line_count -gt 1 ]]; then
      fixes=$((fixes + 1))

      if [[ "$verbose" == true ]]; then
        echo "Line $line_num:"
        echo "  - $line"
        if [[ $fixed_line_count -eq 1 ]]; then
          echo "  + $fixed"
        else
          echo "  +"
          echo "$fixed" | sed 's/^/    /'
        fi
        echo
      fi
    fi

    # Write to temp file
    while IFS= read -r output_line; do
      printf "%s\n" "$output_line" >> "$temp"
    done <<< "$fixed"
  done < "$file"

  # Replace original file
  if [[ -s "$temp" ]]; then
    mv "$temp" "$file"
    chmod --reference="$file" "$file" 2>/dev/null || chmod 644 "$file"
  else
    rm -f "$temp"
    log_error "Generated empty file"
    return 1
  fi

  echo "========================================"
  if (( fixes == 0 )); then
    echo -e "${GREEN}✓ No formatting needed${NC}"
  else
    echo -e "${GREEN}✓ Fixed $fixes line(s)${NC}"
  fi
  echo "========================================"

  return 0
}
