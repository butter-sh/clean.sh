#!/bin/bash
# Test configuration for clean.sh test suite
# This file is sourced by test files to set common configuration

export TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export CLEAN_SH="${TEST_ROOT}/../clean.sh"

# Test directory structure
export CLEAN_SH_ROOT="$PWD"

# Test behavior flags
export CLEAN_TEST_MODE=1

# Color output in tests (set to 0 to disable)
export CLEAN_TEST_COLORS=1
