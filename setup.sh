#!/usr/bin/env bash

# setup.sh - Initialize clean.sh project
# Part of clean.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up clean.sh..."

# Make main script executable
chmod +x "${SCRIPT_DIR}/clean.sh"
echo "✓ Made clean.sh executable"
