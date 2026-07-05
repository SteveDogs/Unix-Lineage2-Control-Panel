#!/usr/bin/env bash

if [ -z "${UNIX_L2_CP_ROOT:-}" ]; then
  UNIX_L2_CP_ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fi

UNIX_L2_CP_NAME="Unix Lineage2 Control Panel"
UNIX_L2_CP_VERSION="1.0.0"
UNIX_L2_CP_SITE="https://steve.dog"
UNIX_L2_CP_AUTHOR="Steve Dog"
UNIX_L2_CP_COPYRIGHT="Copyright (c) 2026 Steve Dog"

UNIX_L2_CP_CONFIG_DIR="${UNIX_L2_CP_CONFIG_DIR:-/etc/unix-l2-control-panel}"
UNIX_L2_CP_SERVER_DIR="${UNIX_L2_CP_SERVER_DIR:-$UNIX_L2_CP_CONFIG_DIR/servers.d}"
UNIX_L2_CP_SETTINGS_FILE="${UNIX_L2_CP_SETTINGS_FILE:-$UNIX_L2_CP_CONFIG_DIR/settings.conf}"
UNIX_L2_CP_STOP_TIMEOUT="${UNIX_L2_CP_STOP_TIMEOUT:-30}"
UNIX_L2_CP_START_WAIT="${UNIX_L2_CP_START_WAIT:-2}"
UNIX_L2_CP_LANG="${UNIX_L2_CP_LANG:-ru}"

load_settings() {
  if [ -f "$UNIX_L2_CP_SETTINGS_FILE" ]; then
    # shellcheck disable=SC1090
    . "$UNIX_L2_CP_SETTINGS_FILE"
  fi

  UNIX_L2_CP_SERVER_DIR="${UNIX_L2_CP_SERVER_DIR:-$UNIX_L2_CP_CONFIG_DIR/servers.d}"
  UNIX_L2_CP_LANG="${UNIX_L2_CP_LANG:-ru}"
}

resolve_real_script() {
  local source_file
  local link_dir

  source_file="$1"
  while [ -L "$source_file" ]; do
    link_dir=$(CDPATH= cd -- "$(dirname -- "$source_file")" && pwd)
    source_file=$(readlink "$source_file")
    case "$source_file" in
      /*) ;;
      *) source_file="$link_dir/$source_file" ;;
    esac
  done
  printf '%s\n' "$source_file"
}

is_true() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

setup_colors() {
  if [ -t 1 ]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'
    C_CYAN=$'\033[36m'
    C_WHITE=$'\033[97m'
  else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_BLUE=""
    C_CYAN=""
    C_WHITE=""
  fi
}

print_brand_header() {
  setup_colors
  printf '%s\n' "${C_CYAN}========================================${C_RESET}"
  printf '%s\n' "${C_BOLD}${UNIX_L2_CP_NAME}${C_RESET}"
  printf '%s\n' "${C_DIM}${UNIX_L2_CP_AUTHOR} | ${UNIX_L2_CP_SITE}${C_RESET}"
  printf '%s\n' "${C_DIM}Version ${UNIX_L2_CP_VERSION}${C_RESET}"
  printf '%s\n' "${C_CYAN}========================================${C_RESET}"
}
