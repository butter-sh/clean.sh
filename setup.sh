#!/usr/bin/env bash

# setup.sh - Initialize clean.sh project
# Part of clean.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up clean.sh..."

# Make main script executable
chmod +x "${SCRIPT_DIR}/clean.sh"
echo "✓ Made clean.sh executable"

# Create necessary directories
mkdir -p "${SCRIPT_DIR}/__tests"
mkdir -p "${SCRIPT_DIR}/examples"
mkdir -p "${SCRIPT_DIR}/.arty/libs"
echo "✓ Created project directories"

# Check for required dependencies
if ! command -v yq &>/dev/null; then
  echo "⚠ Warning: yq not found. Install with: sudo snap install yq"
  echo "  (clean.sh will still work with default configuration)"
fi

echo ""
echo "✓ Setup complete!"
echo ""
echo "Usage:"
echo "  ./clean.sh lint <file>      # Check files for style issues"
echo "  ./clean.sh format <file>    # Fix issues in place"
echo "  ./clean.sh check <file>     # Check without modifying"
echo "  ./clean.sh help             # Show full help"
echo ""
