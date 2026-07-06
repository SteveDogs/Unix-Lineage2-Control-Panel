#!/usr/bin/env bash

declare -ga UL2CP_SERVER_IDS=()
declare -gA UL2CP_SERVER_NAMES=()
declare -gA UL2CP_SERVER_OWNERS=()
declare -gA UL2CP_LOGIN_ENABLED=()
declare -gA UL2CP_LOGIN_DIR=()
declare -gA UL2CP_LOGIN_LOOP=()
declare -gA UL2CP_LOGIN_MATCH=()
declare -gA UL2CP_LOGIN_LOG=()
declare -gA UL2CP_LOGIN_PORT_HINT=()
declare -gA UL2CP_LOGIN_READY_MATCH=()
declare -gA UL2CP_AA_ENABLED=()
declare -gA UL2CP_AA_DIR=()
declare -gA UL2CP_AA_START=()
declare -gA UL2CP_AA_LOOP=()
declare -gA UL2CP_AA_BINARY=()
declare -gA UL2CP_AA_LOG=()
declare -gA UL2CP_AA_PORT_HINT=()
declare -gA UL2CP_AA_READY_MATCH=()
declare -gA UL2CP_AA_SCREEN_NAME=()
declare -gA UL2CP_GAME_ENABLED=()
declare -gA UL2CP_GAME_DIR=()
declare -gA UL2CP_GAME_LOOP=()
declare -gA UL2CP_GAME_MATCH=()
declare -gA UL2CP_GAME_LOG=()
declare -gA UL2CP_GAME_PORT_HINT=()
declare -gA UL2CP_GAME_READY_MATCH=()

reset_server_vars() {
  SERVER_ID=""
  SERVER_NAME=""
  SERVER_OWNER="root"

  LOGIN_ENABLED="false"
  LOGIN_DIR=""
  LOGIN_LOOP="AuthServer_loop.sh"
  LOGIN_MATCH="AuthServer"
  LOGIN_LOG="log/stdout.log"
  LOGIN_PORT_HINT=""
  LOGIN_READY_MATCH=""

  AA_ENABLED="false"
  AA_DIR=""
  AA_START="startscreen.sh"
  AA_LOOP="start.sh"
  AA_BINARY="server"
  AA_LOG="log.txt"
  AA_PORT_HINT=""
  AA_READY_MATCH=""
  AA_SCREEN_NAME=""

  GAME_ENABLED="false"
  GAME_DIR=""
  GAME_LOOP="GameServer_loop.sh"
  GAME_MATCH="GameServer"
  GAME_LOG="log/stdout.log"
  GAME_PORT_HINT=""
  GAME_READY_MATCH=""
}

load_server_file() {
  local file
  file="$1"

  reset_server_vars
  # shellcheck disable=SC1090
  . "$file"

  [ -n "$SERVER_ID" ] || return 0
  [ -n "$SERVER_NAME" ] || SERVER_NAME="$SERVER_ID"

  UL2CP_SERVER_IDS+=("$SERVER_ID")
  UL2CP_SERVER_NAMES["$SERVER_ID"]="$SERVER_NAME"
  UL2CP_SERVER_OWNERS["$SERVER_ID"]="$SERVER_OWNER"

  UL2CP_LOGIN_ENABLED["$SERVER_ID"]="$LOGIN_ENABLED"
  UL2CP_LOGIN_DIR["$SERVER_ID"]="$LOGIN_DIR"
  UL2CP_LOGIN_LOOP["$SERVER_ID"]="$LOGIN_LOOP"
  UL2CP_LOGIN_MATCH["$SERVER_ID"]="$LOGIN_MATCH"
  UL2CP_LOGIN_LOG["$SERVER_ID"]="$LOGIN_LOG"
  UL2CP_LOGIN_PORT_HINT["$SERVER_ID"]="$LOGIN_PORT_HINT"
  UL2CP_LOGIN_READY_MATCH["$SERVER_ID"]="$LOGIN_READY_MATCH"

  UL2CP_AA_ENABLED["$SERVER_ID"]="$AA_ENABLED"
  UL2CP_AA_DIR["$SERVER_ID"]="$AA_DIR"
  UL2CP_AA_START["$SERVER_ID"]="$AA_START"
  UL2CP_AA_LOOP["$SERVER_ID"]="$AA_LOOP"
  UL2CP_AA_BINARY["$SERVER_ID"]="$AA_BINARY"
  UL2CP_AA_LOG["$SERVER_ID"]="$AA_LOG"
  UL2CP_AA_PORT_HINT["$SERVER_ID"]="$AA_PORT_HINT"
  UL2CP_AA_READY_MATCH["$SERVER_ID"]="$AA_READY_MATCH"
  UL2CP_AA_SCREEN_NAME["$SERVER_ID"]="$AA_SCREEN_NAME"

  UL2CP_GAME_ENABLED["$SERVER_ID"]="$GAME_ENABLED"
  UL2CP_GAME_DIR["$SERVER_ID"]="$GAME_DIR"
  UL2CP_GAME_LOOP["$SERVER_ID"]="$GAME_LOOP"
  UL2CP_GAME_MATCH["$SERVER_ID"]="$GAME_MATCH"
  UL2CP_GAME_LOG["$SERVER_ID"]="$GAME_LOG"
  UL2CP_GAME_PORT_HINT["$SERVER_ID"]="$GAME_PORT_HINT"
  UL2CP_GAME_READY_MATCH["$SERVER_ID"]="$GAME_READY_MATCH"
}

load_server_configs() {
  local file
  local found

  UL2CP_SERVER_IDS=()
  UL2CP_SERVER_NAMES=()
  UL2CP_SERVER_OWNERS=()
  UL2CP_LOGIN_ENABLED=()
  UL2CP_LOGIN_DIR=()
  UL2CP_LOGIN_LOOP=()
  UL2CP_LOGIN_MATCH=()
  UL2CP_LOGIN_LOG=()
  UL2CP_LOGIN_PORT_HINT=()
  UL2CP_LOGIN_READY_MATCH=()
  UL2CP_AA_ENABLED=()
  UL2CP_AA_DIR=()
  UL2CP_AA_START=()
  UL2CP_AA_LOOP=()
  UL2CP_AA_BINARY=()
  UL2CP_AA_LOG=()
  UL2CP_AA_PORT_HINT=()
  UL2CP_AA_READY_MATCH=()
  UL2CP_AA_SCREEN_NAME=()
  UL2CP_GAME_ENABLED=()
  UL2CP_GAME_DIR=()
  UL2CP_GAME_LOOP=()
  UL2CP_GAME_MATCH=()
  UL2CP_GAME_LOG=()
  UL2CP_GAME_PORT_HINT=()
  UL2CP_GAME_READY_MATCH=()
  found=0
  shopt -s nullglob
  for file in "$UNIX_L2_CP_SERVER_DIR"/*.conf; do
    found=1
    load_server_file "$file"
  done
  shopt -u nullglob

  [ "$found" -eq 1 ] || return 1
}

server_exists() {
  local id
  id="$1"
  [[ -n "${UL2CP_SERVER_NAMES[$id]:-}" ]]
}

server_label() {
  printf '%s\n' "${UL2CP_SERVER_NAMES[$1]:-$1}"
}

server_owner() {
  printf '%s\n' "${UL2CP_SERVER_OWNERS[$1]:-root}"
}

component_enabled() {
  local id
  local role
  id="$1"
  role="$2"

  case "$role" in
    login) is_true "${UL2CP_LOGIN_ENABLED[$id]:-false}" ;;
    aa) is_true "${UL2CP_AA_ENABLED[$id]:-false}" ;;
    game) is_true "${UL2CP_GAME_ENABLED[$id]:-false}" ;;
    *) return 1 ;;
  esac
}

component_dir() {
  case "$2" in
    login) printf '%s\n' "${UL2CP_LOGIN_DIR[$1]:-}" ;;
    aa) printf '%s\n' "${UL2CP_AA_DIR[$1]:-}" ;;
    game) printf '%s\n' "${UL2CP_GAME_DIR[$1]:-}" ;;
    *) return 1 ;;
  esac
}

component_loop() {
  case "$2" in
    login) printf '%s\n' "${UL2CP_LOGIN_LOOP[$1]:-}" ;;
    aa) printf '%s\n' "${UL2CP_AA_START[$1]:-startscreen.sh}" ;;
    game) printf '%s\n' "${UL2CP_GAME_LOOP[$1]:-}" ;;
    *) return 1 ;;
  esac
}

component_run_loop() {
  case "$2" in
    login) printf '%s\n' "${UL2CP_LOGIN_LOOP[$1]:-}" ;;
    aa) printf '%s\n' "${UL2CP_AA_LOOP[$1]:-start.sh}" ;;
    game) printf '%s\n' "${UL2CP_GAME_LOOP[$1]:-}" ;;
    *) return 1 ;;
  esac
}

component_match() {
  case "$2" in
    login) printf '%s\n' "${UL2CP_LOGIN_MATCH[$1]:-AuthServer}" ;;
    aa) printf '%s\n' "${UL2CP_AA_BINARY[$1]:-server}" ;;
    game) printf '%s\n' "${UL2CP_GAME_MATCH[$1]:-GameServer}" ;;
    *) return 1 ;;
  esac
}

component_log_value() {
  case "$2" in
    login) printf '%s\n' "${UL2CP_LOGIN_LOG[$1]:-log/stdout.log}" ;;
    aa) printf '%s\n' "${UL2CP_AA_LOG[$1]:-log.txt}" ;;
    game) printf '%s\n' "${UL2CP_GAME_LOG[$1]:-log/stdout.log}" ;;
    *) return 1 ;;
  esac
}

component_port_hint() {
  case "$2" in
    login) printf '%s\n' "${UL2CP_LOGIN_PORT_HINT[$1]:-}" ;;
    aa) printf '%s\n' "${UL2CP_AA_PORT_HINT[$1]:-}" ;;
    game) printf '%s\n' "${UL2CP_GAME_PORT_HINT[$1]:-}" ;;
    *) return 1 ;;
  esac
}

component_ready_match() {
  case "$2" in
    login) printf '%s\n' "${UL2CP_LOGIN_READY_MATCH[$1]:-}" ;;
    aa) printf '%s\n' "${UL2CP_AA_READY_MATCH[$1]:-}" ;;
    game) printf '%s\n' "${UL2CP_GAME_READY_MATCH[$1]:-}" ;;
    *) return 1 ;;
  esac
}

component_screen_name() {
  case "$2" in
    aa) printf '%s\n' "${UL2CP_AA_SCREEN_NAME[$1]:-}" ;;
    *) printf '%s\n' "" ;;
  esac
}
