#!/usr/bin/env bash

# example-script.sh - Example bash script for testing clean.sh
# This file contains various bash constructs to test the formatter and linter

set -euo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE=false
CONFIG_FILE="config.yml"

# Array example
declare -a FILES=()
declare -A CONFIG=(
  [max_retries]=3
  [timeout]=30
  [debug]=false
)

# Function with heredoc
show_help() {
  cat <<'EOF'
Usage: example-script.sh [OPTIONS] <command>

Commands:
  start       Start the service
  stop        Stop the service
  status      Check service status

Options:
  -v, --verbose    Enable verbose output
  -c, --config     Specify config file
  -h, --help       Show this help message

Examples:
  example-script.sh start
  example-script.sh -v status
  example-script.sh --config custom.yml start
EOF
}

# Function with parameter expansion
get_config_value() {
  local key="$1"
  local default="${2:-}"

  # Parameter expansion with default
  local value="${CONFIG[$key]:-$default}"

  # Test various bracket styles
  if [[ -n "$value" ]]; then
    echo "$value"
    return 0
  fi

  return 1
}

# Function with arithmetic expansion
calculate_timeout() {
  local base_timeout=$1
  local retry_count=$2

  # Arithmetic expansion
  local total_timeout=$((base_timeout * (retry_count + 1)))

  echo "$total_timeout"
}

# Function with command substitution
get_current_timestamp() {
  # Modern command substitution
  local timestamp
  timestamp=$(date +%s)

  echo "$timestamp"
}

# Function with case statement
process_command() {
  local command="$1"

  case "$command" in
    start)
      echo "Starting service..."
      start_service
      ;;
    stop)
      echo "Stopping service..."
      stop_service
      ;;
    status)
      echo "Checking status..."
      check_status
      ;;
    restart)
      echo "Restarting service..."
      stop_service
      start_service
      ;;
    *)
      echo "Unknown command: $command"
      return 1
      ;;
  esac
}

# Function with loops
start_service() {
  local max_retries="${CONFIG[max_retries]}"
  local retry_count=0

  # While loop
  while [[ $retry_count -lt $max_retries ]]; do
    echo "Attempt $((retry_count + 1))/$max_retries"

    # Simulate service start
    if service_start_attempt; then
      echo "Service started successfully"
      return 0
    fi

    ((retry_count++))
    sleep 1
  done

  echo "Failed to start service after $max_retries attempts"
  return 1
}

# Function with for loop
stop_service() {
  local processes
  processes=$(pgrep -f example-service || true)

  # For loop over command output
  if [[ -n "$processes" ]]; then
    for pid in $processes; do
      echo "Stopping process $pid"
      kill "$pid" 2>/dev/null || true
    done
  fi

  echo "Service stopped"
}

# Function with conditional operators
check_status() {
  # Logical operators with proper spacing
  if [[ -f "$CONFIG_FILE" ]] && [[ -r "$CONFIG_FILE" ]]; then
    echo "Config file exists and is readable"
  elif [[ -f "$CONFIG_FILE" ]] || [[ -f "default.yml" ]]; then
    echo "Using default configuration"
  else
    echo "No configuration found"
    return 1
  fi

  # Regex matching
  local version="v1.2.3"
  if [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Valid version format: $version"
  fi

  return 0
}

# Helper function
service_start_attempt() {
  # Simulate random success/failure
  local random=$((RANDOM % 2))
  [[ $random -eq 0 ]]
}

# Function with brace expansion (should not add spaces)
process_files() {
  # Brace expansion - spacing should be preserved
  for ext in {sh,bash,zsh}; do
    echo "Processing *.$ext files"
  done

  # Numeric range
  for i in {1..10}; do
    echo "Item $i"
  done
}

# Function with glob patterns
find_scripts() {
  local dir="$1"

  # Glob patterns
  for file in "$dir"/*.sh; do
    if [[ -f "$file" ]] && [[ -x "$file" ]]; then
      echo "Found executable script: $file"
    fi
  done
}

# Main function
main() {
  local command=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      -c|--config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -*|--*)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        command="$1"
        shift
        ;;
    esac
  done

  # Validate command
  if [[ -z "$command" ]]; then
    echo "Error: No command specified"
    show_help
    exit 1
  fi

  # Process command
  process_command "$command"
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
