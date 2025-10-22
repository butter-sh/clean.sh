# clean.sh

A POSIX-compliant bash linter and formatter with AST-based parsing.

Part of the [butter.sh](https://github.com/butter-sh) ecosystem.

## Features

✓ **AST-based parsing** using POSIX Shell EBNF grammar
✓ **Idempotent formatting** - running multiple times produces same result
✓ **Configurable rules** via `arty.yml`
✓ **Context-aware** - preserves strings, regex, comments, heredocs
✓ **Intelligent line wrapping** at logical break points
✓ **Severity levels** for linting issues (error, warning, info)
✓ **Heredoc-safe** - never corrupts multi-line strings
✓ **Production-ready** - comprehensive test suite

## Installation

```bash
git clone https://github.com/butter-sh/clean.sh.git
cd clean.sh
bash setup.sh
```

## Usage

### CLI Commands

```bash
# Lint files (read-only check)
./clean.sh lint script.sh

# Format files in place (write/modify)
./clean.sh format script.sh

# Check formatting without modifying
./clean.sh check script.sh

# Parse and show AST (debug)
./clean.sh parse script.sh

# Show help
./clean.sh help
```

### Options

```bash
-c, --config FILE   Use specified config file (default: arty.yml)
-v, --verbose       Enable verbose output
--no-color          Disable colored output
-h, --help          Show help message
```

### Examples

```bash
# Lint a single file
./clean.sh lint examples/example-script.sh

# Format multiple files
./clean.sh format lib/*.sh

# Use custom config
./clean.sh -c custom.yml lint script.sh

# Verbose output
./clean.sh -v format script.sh
```

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
    newline_before_pipe: false  # Break lines before pipes
    lowercase_variables: false  # Enforce lowercase variable names
    use_function_keyword: false # Use 'function' keyword

  severity:
    missing_quotes: warning     # Unquoted variable severity
    line_length: warning        # Line length violation severity
    deprecated_syntax: error    # Deprecated syntax severity
    spacing_issues: warning     # Spacing violation severity
    bracket_style: warning      # Bracket style violation severity
    indentation: warning        # Indentation violation severity
```

## Rules

### Bracket Style

Enforces double brackets `[[ ]]` over single brackets `[ ]` and `test` command:

```bash
# Before
if [ -f "file.txt" ]; then
  test -d "dir"
fi

# After
if [[ -f "file.txt" ]]; then
  [[ -d "dir" ]]
fi
```

### Operator Spacing

Adds proper spacing around logical operators:

```bash
# Before
if [[ -f "a" ]]&&[[ -f "b" ]]; then
  echo "found"
fi

# After
if [[ -f "a" ]] && [[ -f "b" ]]; then
  echo "found"
fi
```

### Indentation

Enforces consistent indentation using spaces:

```bash
# Before
test_func(){
echo "test"
}

# After
test_func() {
  echo "test"
}
```

### Line Length

Warns about lines exceeding maximum length and intelligently wraps at pipes and logical operators:

```bash
# Before
echo "line1" | grep "pattern" | sort | uniq | head -n 10 | tail -n 5 | xargs echo

# After
echo "line1" | grep "pattern" | sort | uniq | head -n 10 | \
  tail -n 5 | \
  xargs echo
```

## Protected Contexts

clean.sh preserves the following contexts without modification:

- **Strings**: `"test [ string ]"`
- **Comments**: `# comment with [ brackets ]`
- **Heredocs**: Multi-line strings with delimiters
- **Regex patterns**: `[[ "$var" =~ pattern ]]`
- **Parameter expansion**: `${var:-default}`, `${#var}`, `${var%suffix}`
- **Arithmetic expansion**: `$((a + b))`
- **Command substitution**: `$(command)`, `` `command` ``
- **Brace expansion**: `{a,b,c}`, `{1..10}`
- **Glob patterns**: `*.sh`, `**/*.txt`, `file[0-9].txt`
- **Process substitution**: `<(command)`

## Integration with arty.sh

Add to your `arty.yml`:

```yaml
dependencies:
  clean.sh: "^1.0.0"

scripts:
  lint: "./clean.sh lint *.sh lib/*.sh"
  format: "./clean.sh format *.sh lib/*.sh"
  check: "./clean.sh check *.sh lib/*.sh"
```

Then run:

```bash
arty lint
arty format
arty check
```

## Testing

Run the comprehensive test suite:

```bash
# Run all tests
bash __tests/test-clean-cli.sh
bash __tests/test-clean-linter.sh
bash __tests/test-clean-formatter.sh
bash __tests/test-clean-edge-cases.sh

# Or with judge.sh
arty test
```

## Architecture

### Modules

- **clean.sh**: Main CLI entry point with command parsing
- **lib/parser.sh**: POSIX-compliant AST parser based on EBNF grammar
- **lib/linter.sh**: Read-only linting engine with rule validation
- **lib/formatter.sh**: Formatting engine with heredoc-safe implementation

### Parser

The parser implements POSIX Shell grammar sections:

- **B.8**: Parameter Expansion
- **B.9**: Command Substitution
- **B.10**: Arithmetic Expansion
- **B.15**: Here Document
- **B.18**: IO Redirection
- **B.19**: Shell Glob Pattern

Reference: [POSIX Shell Command Language](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)

### Formatter Safety

The formatter uses state tracking to ensure heredocs are never corrupted:

```bash
format_file() {
  local in_heredoc=false
  local heredoc_delimiter=""

  while IFS= read -r line; do
    # Detect heredoc start
    if detect_heredoc_start "$line"; then
      in_heredoc=true
      heredoc_delimiter=$(extract_heredoc_delimiter "$line")
    fi

    # Preserve heredoc content exactly
    if [[ "$in_heredoc" == true ]]; then
      printf "%s\n" "$line"  # Output as-is
      continue
    fi

    # Format normal lines
    format_line "$line" "$indent_level"
  done
}
```

## Development

### Project Structure

```
clean.sh/
├── arty.yml              # Project configuration
├── clean.sh              # Main CLI
├── setup.sh              # Setup script
├── README.md             # Documentation
├── lib/
│   ├── parser.sh         # POSIX parser
│   ├── linter.sh         # Linting engine
│   └── formatter.sh      # Formatting engine
├── examples/
│   └── example-script.sh # Example bash script
└── __tests/
    ├── test-clean-cli.sh
    ├── test-clean-linter.sh
    ├── test-clean-formatter.sh
    └── test-clean-edge-cases.sh
```

### Adding Rules

1. Add rule configuration to `arty.yml`:

```yaml
clean:
  rules:
    my_new_rule: true

  severity:
    my_new_rule: warning
```

2. Add check function to `lib/linter.sh`:

```bash
check_my_new_rule() {
  local line="$1"
  local line_num="$2"

  if [[ "$line" =~ pattern ]]; then
    add_issue "warning" "my_new_rule" "$line_num" "Issue message"
    return 1
  fi

  return 0
}
```

3. Add fix function to `lib/formatter.sh`:

```bash
fix_my_new_rule() {
  local line="$1"

  if [[ "${CONFIG[my_new_rule]}" != "true" ]]; then
    echo "$line"
    return 0
  fi

  # Apply fix
  local fixed
  fixed=$(echo "$line" | sed 's/pattern/replacement/')

  echo "$fixed"
}
```

4. Add tests to `__tests/test-clean-linter.sh` and `__tests/test-clean-formatter.sh`

## Known Limitations

- Does not support multiline command parsing (commands split across lines with `\`)
- Line wrapping is limited to pipes and logical operators
- Does not detect all possible quoting issues (heuristic-based)
- Arithmetic expansion patterns must be simple to avoid regex syntax errors

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Author

Part of butter.sh ecosystem by valknar@pivoine.art

## References

- [POSIX Shell Command Language](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [POSIX Shell EBNF Grammar](https://github.com/butter-sh/_assets/posix-shell.ebnf)
- [judge.sh Testing Framework](https://github.com/butter-sh/judge.sh)
- [arty.sh Package Manager](https://github.com/butter-sh/arty.sh)
