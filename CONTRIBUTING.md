
# Contributing

Thanks for your interest in contributing!

## Quick start

1. **Fork** the repo and create a branch
   - Use a descriptive name like `fix-typo`, `bug/issue-123`, or `feature/add-foo`.

2. **Make your changes**
   - Keep changes focused and easy to review.
   - Add or update tests/docs when it makes sense.

3. **Run checks locally**
   - Run tests:
     ```bash
     bash tests/run.bash
     ```
   - Check shell scripts with [ShellCheck](https://www.shellcheck.net/):
     ```bash
     shellcheck -x ./python **/*.bash
     ```
4. **Open a Pull Request**
   - Describe *what* changed and *why*.
   - Include steps to test/verify the change (commands + expected result).
   - Link any related issue(s), if applicable.

## Reporting bugs / requesting features

Please open an issue with:
- what you expected vs what happened
- steps to reproduce
- version/environment details (OS, bash version, etc.)
- logs/error messages if relevant

## Code style

- Match the existing style and conventions in the codebase.
- Prefer small, readable changes over large refactors.

## License

By contributing, you agree that your contributions will be licensed under the MIT License (see `LICENSE`).
