#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Test helpers for uv-python-shim tests.
# Sourced by tests/run.bash
# -----------------------------------------------------------------------------

set -euo pipefail

failures=0
tests_run=0

TESTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd -- "${TESTS_DIR}/.." && pwd)"

assert_grep() {
  local pattern="$1" file="$2"
  grep -E -q -- "$pattern" "$file" || {
    echo "ASSERT FAILED: pattern not found: $pattern in $file" >&2
    echo "---- file contents ----" >&2
    cat "$file" >&2
    echo "-----------------------" >&2
    return 1
  }
}

refute_grep() {
  local pattern="$1" file="$2"
  if grep -E -q -- "$pattern" "$file"; then
    echo "ASSERT FAILED: unexpected pattern found: $pattern in $file" >&2
    echo "---- file contents ----" >&2
    cat "$file" >&2
    echo "-----------------------" >&2
    return 1
  fi
}

run_test() {
  local name="$1"
  tests_run=$((tests_run+1))
  echo "==> $name"
  if "$name"; then
    echo "PASS: $name"
  else
    echo "FAIL: $name" >&2
    failures=$((failures+1))
  fi
  echo
}

setup_test_root() {
  local root here
  root="$(mktemp -d -t uv-python-shim-test.XXXXXX)" || return 1

  mkdir -p "$root/out" "$root/shims" "$root/tests/bin" "$root/tests/lib" || return 1

  # Copy shim-under-test
  cp -- "${PROJECT_ROOT}/python" "$root/shims/python" || return 1
  chmod +x "$root/shims/python" || return 1

  # Copy stubs
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || return 1
  cp -- "$here/bin/uv" "$root/tests/bin/uv" || return 1
  cp -- "$here/bin/py_default" "$root/tests/bin/py_default" || return 1
  cp -- "$here/bin/py_314" "$root/tests/bin/py_314" || return 1
  chmod +x "$root/tests/bin/uv" "$root/tests/bin/py_default" "$root/tests/bin/py_314" || return 1

  printf '%s\n' "$root"
}

teardown_test_root() {
  local root="$1"
  rm -rf "$root"
}

setup_shims_and_path() {
  local root="$1"
  export SHIM_DIR="$root/shims"
  export UV_MOCK_LOG="$root/out/uv.log"
  : >"$UV_MOCK_LOG"

  # Put shims first on PATH (like real usage), then stubs.
  export PATH="$root/shims:$root/tests/bin:/usr/bin:/bin"
}

run_shim() {
  # args: <root> <shim-path> <stdout-file> <stderr-file> [args...]
  local root="$1" shim="$2" out="$3" err="$4"
  shift 4
  "$shim" "$@" >"$out" 2>"$err"
}

finalize() {
  echo "Tests run: $tests_run"
  if (( failures > 0 )); then
    echo "Failures: $failures" >&2
    exit 1
  fi
  echo "ALL TESTS PASSED"
}
