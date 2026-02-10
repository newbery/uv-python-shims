#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# uv-python-shim tests
#
# Shim under test: ./python
# Test helpers:    tests/lib/test-helpers.bash
# Test stubs:      tests/bin/*
# -----------------------------------------------------------------------------

set -euo pipefail

TESTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=tests/lib/test-helpers.bash
source "${TESTS_DIR}/lib/test-helpers.bash"


# Contract: 'python' shim should use default python found from 'uv python find'
test_python_default() {
  # Given
  local root out err log
  root="$(setup_test_root)" || return 1
  setup_shims_and_path "$root"

  out="$root/out/stdout.txt"
  err="$root/out/stderr.txt"
  log="$root/out/uv.log"

  export UV_FIND_PATH="$root/tests/bin/py_default"

  # When
  run_shim "$root" "$root/shims/python" "$out" "$err" -c 'print("hi")'

  # Then
  assert_grep '^PY=default$' "$out"
  assert_grep '^ARGV=-c print\("hi"\)$' "$out"

  # Executed python should not see shim dir in PATH (recursion safety)
  refute_grep "$root/shims" "$out"

  assert_grep '^uv python find --resolve-links$' "$log"
  refute_grep '--show-version' "$log"

  teardown_test_root "$root"
}

# Contract: 'python3.10' shim should use default found python
# if shim prefix matches default found python version prefix
test_python310_when_default_matches() {
  # Given
  local root out err log
  root="$(setup_test_root)" || return 1
  setup_shims_and_path "$root"

  ln -sf python "$root/shims/python3.10"

  out="$root/out/stdout.txt"
  err="$root/out/stderr.txt"
  log="$root/out/uv.log"

  export UV_FIND_VERSION="3.10.19"
  export UV_FIND_PATH="$root/tests/bin/py_default"

  # When
  run_shim "$root" "$root/shims/python3.10" "$out" "$err" -V

  # Then
  assert_grep '^PY=default$' "$out"
  assert_grep '^uv python find --show-version --resolve-links$' "$log"
  refute_grep 'find --resolve-links 3\.10$' "$log"

  teardown_test_root "$root"
}

# Contract: 'python3.14' shim should use python found with shim prefix
# if shim prefix does NOT match default found python version prefix
test_python314_when_default_does_not_match() {
  # Given
  local root out err log
  root="$(setup_test_root)" || return 1
  setup_shims_and_path "$root"

  ln -sf python "$root/shims/python3.14"

  out="$root/out/stdout.txt"
  err="$root/out/stderr.txt"
  log="$root/out/uv.log"

  export UV_FIND_VERSION="3.10.19"
  export UV_FIND_PATH="$root/tests/bin/py_default"
  export UV_FIND_PATH_3_14="$root/tests/bin/py_314"

  # When
  run_shim "$root" "$root/shims/python3.14" "$out" "$err" -c 'x=1'

  # Then
  assert_grep '^PY=3\.14$' "$out"
  assert_grep '^uv python find --show-version --resolve-links$' "$log"
  assert_grep '^uv python find --resolve-links 3\.14$' "$log"

  teardown_test_root "$root"
}

# Contract: 'python3.14' shim should use python found with shim prefix
# if default python find returns nothing (e.g. via bad version spec in project)
test_python314_when_default_is_missing() {
  # Given
  local root out err log
  root="$(setup_test_root)" || return 1
  setup_shims_and_path "$root"

  ln -sf python "$root/shims/python3.14"

  out="$root/out/stdout.txt"
  err="$root/out/stderr.txt"
  log="$root/out/uv.log"

  unset UV_FIND_VERSION || true
  export UV_FIND_PATH_3_14="$root/tests/bin/py_314"

  # When
  run_shim "$root" "$root/shims/python3.14" "$out" "$err" -c 'x=1'

  # Then
  assert_grep '^PY=3\.14$' "$out"
  assert_grep '--show-version' "$log"
  assert_grep 'find --resolve-links 3\.14$' "$log"

  teardown_test_root "$root"
}

run_test test_python_default
run_test test_python310_when_default_matches
run_test test_python314_when_default_does_not_match
run_test test_python314_when_default_is_missing

finalize
