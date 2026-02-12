#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# install.bash
#
# Copies the project-root ./python shim to:
#   ~/.local/uv-python-shims/python
#
# Then creates symlinks:
#   python3, python3.9, python3.10, ... python3.14
#
# Controls:
#   DEST_DIR=...   change install directory
#   PAUSE=0.2      slow down / speed up (seconds). Use PAUSE=0 to disable.
# -----------------------------------------------------------------------------

set -euo pipefail

DEST_DIR="${DEST_DIR:-$HOME/.local/uv-python-shims}"
PAUSE="${PAUSE:-0.08}"
MINOR_VERSIONS="${MINOR_VERSIONS:-9 10 11 12 13 14}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_SHIM="${SCRIPT_DIR}/python"
DEST_SHIM="${DEST_DIR}/python"

pause() {
  [[ "${PAUSE}" == "0" || "${PAUSE}" == "0.0" ]] && return 0
  sleep "${PAUSE}"
}

run_step() {
  local desc="$1"; shift
  pause
  "$@"
  ok "$desc"
  pause
}

# ----------------------------
# Some simple color setup
# ----------------------------

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
  C_CYAN=$'\033[36m'
else
  C_RESET=""; C_BOLD=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_CYAN=""
fi

info() { printf "%s==>%s %s\n"     "${C_CYAN}${C_BOLD}"  "${C_RESET}"  "$*" ; }
ok()   { printf "%s✔%s %s\n"       "${C_GREEN}"          "${C_RESET}"  "$*" ; }
warn() { printf "%s!%s %s\n"       "${C_YELLOW}"         "${C_RESET}"  "$*" ; }
err()  { printf "%sERROR:%s %s\n"  "${C_RED}${C_BOLD}"   "${C_RESET}"  "$*" >&2; }


# ----------------------------
# Do the work...
# ----------------------------

info "Install uv python shims"
printf "  Source:      %s\n" "${SRC_SHIM}"
printf "  Destination: %s\n\n" "${DEST_SHIM}"

if [[ ! -f "${SRC_SHIM}" ]]; then
  err "Shim not found at: ${SRC_SHIM}"
  err "Expected a file named 'python' in the project root next to install.bash"
  exit 1
fi

info "Create main shim"
run_step "Create directory ${DEST_DIR}" mkdir -p "${DEST_DIR}"
run_step "Copy shim to ${DEST_SHIM}" cp "${SRC_SHIM}" "${DEST_SHIM}"
run_step "Set executable bit on ${DEST_SHIM}" chmod 0755 "${DEST_SHIM}"
printf "\n"

info "Create symlinks"
run_step "Link ${DEST_DIR}/python3 -> python" ln -sfn "python" "${DEST_DIR}/python3"
for minor in ${MINOR_VERSIONS}; do
  run_step "Link ${DEST_DIR}/python3.${minor} -> python" ln -sfn "python" "${DEST_DIR}/python3.${minor}"
done

printf "\n"
info "Done"

cat <<EOF

${C_BOLD}Activate shims${C_RESET}
Add this to your shell startup file:

  export PATH="${DEST_DIR}:\$PATH"

${C_BOLD}Common locations${C_RESET}
  bash: ~/.bashrc (and/or ~/.bash_profile)
  zsh : ~/.zshrc

Then restart your shell, or run:

  export PATH="${DEST_DIR}:\$PATH"

${C_BOLD}Verify result${C_RESET}
  which python
  which python3.11
  python --version
  python3.11 --version

${C_BOLD}Install can be customized${C_RESET}
  PAUSE=0        bash ./install.bash
  PAUSE=0.25     bash ./install.bash
  DEST_DIR=...   bash ./install.bash

EOF
