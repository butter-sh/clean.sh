#!/usr/bin/env bash

# clean.sh - POSIX-compliant Bash Linter and Formatter
# Part of the butter.sh ecosystem
# Version: 1.0.0

set -euo pipefail

# Script directory resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_BASH_SOURCE="$(readlink -f "${BASH_SOURCE[0]}")"
REAL_SCRIPT_DIR="$(cd "$(dirname "${REAL_BASH_SOURCE}")" && pwd)"

# Colors for output
export FORCE_COLOR=${FORCE_COLOR:-"1"}
if [[ "$FORCE_COLOR" = "0" ]]; then
  export RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' BOLD='' NC=''
  else
  export RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
  export BLUE='\033[0;34m' CYAN='\033[0;36m' MAGENTA='\033[0;35m'
  export BOLD='\033[1m' NC='\033[0m'
fi

# Logging functions
log_info() { echo -e "${BLUE}[ℹ]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[✓]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $1" >&2; }
log_error() { echo -e "${RED}[✗]${NC} $1" >&2; }

# Default configuration
declare -A CONFIG=(
[max_line_length]=100
[indent_size]=2
[use_spaces]=true
[use_double_brackets]=true
[space_around_operators]=true
[space_after_comma]=true
[space_before_brace]=true
[newline_before_pipe]=false
[quote_variables]=true
[lowercase_variables]=false
[use_function_keyword]=false
)

declare -A SEVERITY=(
[missing_quotes]=warning
[line_length]=warning
[deprecated_syntax]=error
[spacing_issues]=warning
[bracket_style]=warning
[indentation]=warning
)

# Load configuration from arty.yml using yq
load_config() {
  local config_file="${1:-arty.yml}"

  if [[ ! -f "$config_file" ]]; then
    return 0
  fi

  # Check if yq is available
  if ! command -v yq &>/dev/null; then
    log_warn "yq not found, using default configuration"
    return 0
  fi

  # Check if YAML is valid
  if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
    log_warn "Invalid YAML in config file, using defaults"
    return 0
  fi

  # Load clean.rules section
  local rules_exist
  rules_exist=$(yq eval '.clean.rules' "$config_file" 2>/dev/null)

  if [[ "$rules_exist" != "null" ]] && [[ -n "$rules_exist" ]]; then
    for key in "${!CONFIG[@]}"; do
      local value
      value=$(yq eval ".clean.rules.$key" "$config_file" 2>/dev/null)
      if [[ "$value" != "null" ]] && [[ -n "$value" ]]; then
        CONFIG[$key]="$value"
      fi
    done
  fi

  # Load severity levels
  local severity_exist
  severity_exist=$(yq eval '.clean.severity' "$config_file" 2>/dev/null)

  if [[ "$severity_exist" != "null" ]] && [[ -n "$severity_exist" ]]; then
    for key in "${!SEVERITY[@]}"; do
      local value
      value=$(yq eval ".clean.severity.$key" "$config_file" 2>/dev/null)
      if [[ "$value" != "null" ]] && [[ -n "$value" ]]; then
        SEVERITY[$key]="$value"
      fi
    done
  fi
}

# Source lib modules
source "${REAL_SCRIPT_DIR}/lib/parser.sh"
source "${REAL_SCRIPT_DIR}/lib/linter.sh"
source "${REAL_SCRIPT_DIR}/lib/formatter.sh"

# Show usage
show_usage() {
  cat << 'USAGE_EOF'
clean.sh - POSIX-compliant Bash Linter and Formatter
Part of the butter.sh ecosystem

USAGE:
  clean.sh <command> [options] <file>...

COMMANDS:
  lint            Check files for style issues (read-only)
  format          Fix issues in place (write)
  check           Check formatting without modifying files
  parse           Parse file and output AST (debug)
  help            Show this help message

OPTIONS:
  -c, --config FILE   Use specified config file (default: arty.yml)
  -v, --verbose       Enable verbose output
  --no-color          Disable colored output
  -h, --help          Show this help message

CONFIGURATION:
  Configuration is read from arty.yml under the clean.rules section:

  clean:
    rules:
      max_line_length: 100
      indent_size: 2
      use_spaces: true
      use_double_brackets: true
      space_around_operators: true
      space_after_comma: true
      space_before_brace: true
      quote_variables: true

    severity:
      missing_quotes: warning
      line_length: warning
      deprecated_syntax: error
      spacing_issues: warning
      bracket_style: warning

FEATURES:
  ✓ AST-based parsing using POSIX EBNF grammar
  ✓ Idempotent formatting
  ✓ Configurable rules via arty.yml
  ✓ Context-aware (preserves strings, regex, comments, heredocs)
  ✓ Intelligent line wrapping
  ✓ Severity levels for linting issues

EXAMPLES:
  # Lint a file
  clean.sh lint script.sh

  # Format files in place
  clean.sh format script.sh

  # Check multiple files
  clean.sh check *.sh

  # Use custom config
  clean.sh -c custom.yml lint script.sh

  # Parse and show AST (debug)
  clean.sh parse script.sh

INTEGRATION:
  # Via arty.sh
  arty lint
  arty format
  arty check

AUTHOR:
  Part of butter.sh - https://github.com/butter-sh

USAGE_EOF
}

# Main function
main() {
  local config_file="arty.yml"
  local verbose=false
  local command=""
  local files=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -c|--config)
    config_file="$2"
    shift 2
    ;;
    -v|--verbose)
    verbose=true
    shift
    ;;
    --no-color)
    export FORCE_COLOR=0
    shift
    ;;
    -h|--help)
    show_usage
    exit 0
    ;;
    lint|format|check|parse)
    command="$1"
    shift
    ;;
    help)
    show_usage
    exit 0
    ;;
    -*)
    log_error "Unknown option: $1"
    exit 1
    ;;
    *)
  files+=("$1")
  shift
  ;;
esac
done

  # Load configuration
load_config "$config_file"

  # Validate command
if [[ -z "$command" ]]; then
  log_error "No command specified"
  show_usage
  exit 1
fi

  # Validate files
if [[ ${#files[@]} -eq 0 ]]; then
  log_error "No files specified"
  echo "Usage: clean.sh $command <file>..."
  exit 1
fi

  # Execute command
local exit_code=0

case "$command" in
lint)
for file in "${files[@]}"; do
  lint_file "$file" "$verbose" || exit_code=1
done
;;
format)
for file in "${files[@]}"; do
  format_file "$file" "$verbose" || exit_code=1
done
;;
check)
for file in "${files[@]}"; do
  check_file "$file" "$verbose" || exit_code=1
done
;;
parse)
for file in "${files[@]}"; do
  parse_file "$file" "$verbose" || exit_code=1
done
;;
*)
log_error "Unknown command: $command"
exit 1
;;
esac

exit $exit_code
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
