<div align="center">

<img src="./icon.svg" width="100" height="100" alt="clean.sh">

# clean.sh

**Bash Linter & Formatter**

[![Organization](https://img.shields.io/badge/org-butter--sh-4ade80?style=for-the-badge&logo=github&logoColor=white)](https://github.com/butter-sh)
[![License](https://img.shields.io/badge/license-MIT-86efac?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-22c55e?style=for-the-badge)](https://github.com/butter-sh/clean.sh/releases)
[![butter.sh](https://img.shields.io/badge/butter.sh-clean-4ade80?style=for-the-badge)](https://butter-sh.github.io)

*POSIX-compliant bash linter and formatter with AST-based parsing and intelligent rule detection*

[Documentation](https://butter-sh.github.io/clean.sh) • [GitHub](https://github.com/butter-sh/clean.sh) • [butter.sh](https://github.com/butter-sh)

</div>

---

## Overview

clean.sh is a professional linter and formatter for bash scripts, providing intelligent style enforcement and automatic code corrections. Built with AST-based parsing, it understands shell syntax deeply and applies rules with context awareness, preserving heredocs, comments, and string literals.

### Key Features

- **AST-Based Parsing** — Deep syntactic understanding using POSIX Shell EBNF grammar
- **Auto-Fix Formatting** — Automatically correct style issues in place
- **Intelligent Rules** — Context-aware detection with protected contexts
- **Style Enforcement** — Consistent coding standards across projects
- **Heredoc Preservation** — Safe handling of heredocs, strings, and special contexts
- **Idempotent** — Running multiple times produces same result
- **Configurable** — Customize rules and severity levels via arty.yml

---

## Installation

### Using arty.sh

```bash
arty install https://github.com/butter-sh/clean.sh.git
arty exec clean --help
```

### Manual Installation

```bash
git clone https://github.com/butter-sh/clean.sh.git
cd clean.sh
sudo cp clean.sh /usr/local/bin/clean
sudo chmod +x /usr/local/bin/clean
```

---

## Usage

### Lint Scripts

Check scripts for style issues without modifying them:

```bash
clean lint script.sh
clean lint lib/*.sh
```

### Format Scripts

Automatically fix style issues:

```bash
clean format script.sh
clean format **/*.sh
```

### Check Without Modifying

Alias for lint (non-destructive check):

```bash
clean check script.sh
```

### Options

```bash
-c, --config FILE   Use specified config file (default: arty.yml)
-v, --verbose       Enable verbose output
--no-color          Disable colored output
-h, --help          Show help message
```

---

## Linting Rules

### Bracket Style

Enforces double brackets `[[ ]]` over single brackets `[ ]`:

```bash
# Before
if [ -f "file.txt" ]; then
  echo "found"
fi

# After
if [[ -f "file.txt" ]]; then
  echo "found"
fi
```

### Test Command Conversion

Converts `test` command to double brackets:

```bash
# Before
if test -f "file.txt"; then
  echo "found"
fi

# After
if [[ -f "file.txt" ]]; then
  echo "found"
fi
```

### Operator Spacing

Ensures proper spacing around logical operators:

```bash
# Before
if [[ -f "a" ]]&&[[ -f "b" ]]; then
  echo "both found"
fi

# After
if [[ -f "a" ]] && [[ -f "b" ]]; then
  echo "both found"
fi
```

### Indentation

Enforces consistent indentation (spaces, not tabs):

```bash
# Before
function test_func() {
echo "test"
}

# After
function test_func() {
  echo "test"
fi
```

### Line Length

Warns about lines exceeding maximum length (default: 100 characters).

---

## Configuration

Configuration is read from `arty.yml` under the `clean` section:

```yaml
clean:
  rules:
    max_line_length: 100        # Maximum line length
    indent_size: 2              # Spaces per indent level
    use_spaces: true            # Use spaces instead of tabs
    use_double_brackets: true   # Use [[ ]] instead of [ ]
    space_around_operators: true # Add spaces around && and ||
    space_after_comma: true     # Add space after commas
    space_before_brace: true    # Add space before {
    quote_variables: true       # Warn about unquoted variables

  severity:
    missing_quotes: warning     # Unquoted variable severity
    line_length: warning        # Line length violation severity
    deprecated_syntax: error    # Deprecated syntax severity
    spacing_issues: warning     # Spacing violation severity
    bracket_style: warning      # Bracket style violation severity
```

---

## Protected Contexts

clean.sh preserves special contexts without modification:

### Heredocs

```bash
cat << 'EOF'
This [ content ] is preserved exactly
Even with && operators and test commands
EOF
```

### Comments

```bash
# This [ comment ] is preserved
# Even with test and && operators
```

### String Literals

```bash
VAR="test [ string ] with && operators"
echo "$VAR"  # String content is preserved
```

### Other Protected Contexts

- **Regex patterns**: `[[ "$var" =~ pattern ]]`
- **Parameter expansion**: `${var:-default}`, `${#var}`
- **Arithmetic expansion**: `$((a + b))`
- **Command substitution**: `$(command)`
- **Brace expansion**: `{a,b,c}`, `{1..10}`
- **Glob patterns**: `*.sh`, `**/*.txt`
- **Process substitution**: `<(command)`

---

## Integration with arty.sh

Add clean.sh to your project's `arty.yml`:

```yaml
name: "my-project"
version: "1.0.0"

references:
  - https://github.com/butter-sh/clean.sh.git

scripts:
  lint: "arty exec clean lint *.sh"
  format: "arty exec clean format *.sh"
  check: "arty exec clean check *.sh"
```

Then run:

```bash
arty deps     # Install clean.sh
arty lint     # Run linter
arty format   # Auto-format code
```

---

## Examples

### Format All Project Scripts

```bash
clean format *.sh
clean format __tests/*.sh
clean format lib/*.sh
```

### Lint Before Commit

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit

clean lint $(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$')
```

### CI Integration

```yaml
# .github/workflows/lint.yml
name: Lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install clean.sh
        run: |
          git clone https://github.com/butter-sh/clean.sh.git
          sudo cp clean.sh/clean.sh /usr/local/bin/clean
      - name: Lint scripts
        run: clean lint **/*.sh
```

---

## Architecture

### Modules

- **clean.sh** — Main CLI entry point with command parsing
- **lib/parser.sh** — POSIX-compliant AST parser based on EBNF grammar
- **lib/linter.sh** — Read-only linting engine with rule validation
- **lib/formatter.sh** — Formatting engine with heredoc-safe implementation

### Parser

Implements POSIX Shell grammar sections:
- **B.8** — Parameter Expansion
- **B.9** — Command Substitution
- **B.10** — Arithmetic Expansion
- **B.15** — Here Document
- **B.18** — IO Redirection
- **B.19** — Shell Glob Pattern

Reference: [POSIX Shell Command Language](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)

---

## Exit Codes

- `0` — Success, no errors found
- `1` — Errors detected or formatting failed

Warnings and info messages don't cause non-zero exit codes.

---

## Related Projects

Part of the [butter.sh](https://github.com/butter-sh) ecosystem:

- **[arty.sh](https://github.com/butter-sh/arty.sh)** — Dependency manager
- **[judge.sh](https://github.com/butter-sh/judge.sh)** — Testing framework
- **[myst.sh](https://github.com/butter-sh/myst.sh)** — Templating engine
- **[hammer.sh](https://github.com/butter-sh/hammer.sh)** — Project scaffolding
- **[leaf.sh](https://github.com/butter-sh/leaf.sh)** — Documentation generator
- **[whip.sh](https://github.com/butter-sh/whip.sh)** — Release management

---

## License

MIT License — see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

<div align="center">

**Part of the [butter.sh](https://github.com/butter-sh) ecosystem**

*Unlimited. Independent. Fresh.*

Crafted by [Valknar](https://github.com/valknarogg)

</div>
