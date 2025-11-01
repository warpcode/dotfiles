Follow all instructions

# Code Style and Development Guidelines

## Shell Scripting (Zsh/Bash)

### Formatting
- Use LF line endings, UTF-8 encoding, insert final newline
- Indent with 2 spaces for shell scripts (4 spaces for Python)
- Limit lines to 110 characters
- Avoid trailing whitespace

### Zsh-Specific Guidelines
- **Primary Shell**: Assume Zsh as the primary shell unless explicitly stated otherwise
- **Variable Declaration**: Use Zsh-appropriate patterns (e.g., `local var=$(command)` is acceptable in Zsh)
- **Array Handling**: Use Zsh array syntax (`array=($(command))` not bash-specific `mapfile`
- **Error Checking**: Zsh error checking patterns are acceptable (`if [[ $? -ne 0 ]]`)
- **Command Availability**: Check with `(( $+commands[cmd] ))` in Zsh
- **Shellcheck**: Note that shellcheck has limited Zsh support - some warnings are expected

### General Shell Best Practices
- Prefer POSIX-compliant syntax for portability where possible
- Use lowercase variables with underscores, functions with underscores
- Use `UPPER_CASE` for environment variables
- Add comments for non-obvious logic
- Quote variables properly: `"$variable"`
- Use `local` for function-scoped variables
- Handle errors gracefully; exit nonzero on failure
- Check command availability before use

### Security Requirements
- **Input Validation**: Always validate user input, especially repository names
  ```zsh
  if [[ ! $repo =~ ^[a-zA-Z0-9._/-]+$ ]]; then
      echo "❌ Invalid repo name: $repo" >&2
      return 1
  fi
  ```
- **URL Construction**: Always quote URL variables to prevent injection
  ```zsh
  local url="https://example.com/path/${version#v}/file.sh"
  ```
- **Command Injection**: Never use untrusted data in command substitution without validation

### Error Handling Patterns
- Use consistent error messages with emoji indicators
- Return non-zero on failure
- Provide clear usage instructions in error messages
- Log errors to stderr (`>&2`)

## Python Scripts

### Formatting
- Use Python 3 shebang: `#!/usr/bin/env python3`
- Follow PEP 8 style (4 spaces indentation)
- Use `argparse` for CLI arguments
- Limit lines to 110 characters

## Project Structure

### Zsh Configuration Organization
- **Functions**: Place in `src/zsh/functions/`
- **Apps**: Place in `src/zsh/apps/`
- **Config**: Place in `src/zsh/config/`
- **Installers**: Place in `src/zsh/installers/`
- **Projects**: Place in `src/zsh/projects/`

### Loading Order
Respect the loading order defined in `src/zsh/init.zsh`:
1. Default environment and Zsh settings
2. Functions
3. Apps
4. Projects
5. User overrides (`~/.zshrc.d/`, etc.)

### Stow Compatibility
- Consider how new dotfiles integrate with GNU Stow
- Place files in appropriate top-level directories (`generic/`, `work/`)
- Use relative paths where possible

## Code Review Guidelines

### Security First
- Always check for command injection vulnerabilities
- Validate all external input
- Review URL construction and file operations
- Ensure proper quoting of variables

### Quality Standards
- Functions should have appropriate comment blocks
- Documentation should explain "why" not "what"
- Avoid unnecessary comments
- Follow consistent error message format
- Test error paths

### Zsh Compatibility
- Do not use bash-specific patterns in Zsh files
- Be aware of shellcheck limitations with Zsh
- Test with Zsh, not bash
- Use Zsh-specific features where appropriate

## Installer System

### Version Management
- Use semantic version comparison
- Skip installations when versions match
- Provide clear feedback about version mismatches
- Support "latest", "main", "master" keywords

### Package Registration
- Use `_installer_package` function for package registration
- Implement post-install hooks for additional setup
- Handle platform-specific installation requirements
- Provide rollback capability where possible

### Error Handling
- Always check command exit codes
- Provide meaningful error messages
- Clean up partial installations on failure
- Log installation progress

## Naming Conventions

### Files
- Use lowercase-with-dashes.zsh for shell scripts
- Use descriptive names that indicate functionality

### Functions and Variables
- Use `snake_case` for functions and variables
- Prefix functions with module name when applicable (e.g., `_gh_` for GitHub functions)
- Use `UPPER_CASE` for constants and environment variables

## Testing

### Manual Testing
- No automated test framework currently
- Verify syntax with `zsh -n filename.zsh`
- Test scripts manually: `zsh path/to/script.zsh`
- Test error conditions and edge cases

### Cross-Platform Considerations
- Test on target platforms (macOS, Linux variants)
- Handle platform-specific differences
- Use conditional logic for platform-specific code

## Git Commit Guidelines

### Commit Message Style
- Use present tense ("Add feature" not "Added feature")
- Focus on "why" not "what"
- Include technical details for significant changes
- Group related changes in single commit

### Branch Naming
- Use descriptive branch names
- Include feature/fix prefix when appropriate
- Keep names concise but informative

## Security Considerations

### Remote Content
- Always warn users about manual verification requirements
- Never execute remote content without user awareness
- Consider checksum verification where available
- Implement user confirmation for critical operations

### File Operations
- Use path traversal protection
- Validate file paths and permissions
- Handle symlinks carefully
- Clean up temporary files

## AI Interaction Guidelines

### Context Awareness
- Understand this is a dotfiles repository
- Prioritize command-line oriented solutions
- Consider shell-script based approaches
- Respect existing project structure

### Code Generation
- Follow established patterns and conventions
- Maintain consistency with existing codebase
- Consider integration with installer system
- Test for compatibility with existing functions

### Security Mindset
- Always consider security implications
- Validate all inputs and outputs
- Use secure coding practices
- Document security considerations
