#!/usr/bin/env bash

component_log_path() {
  local value
  local dir

  value=$(component_log_value "$1" "$2") || return 1
  dir=$(component_dir "$1" "$2") || return 1

  case "$value" in
    /*) printf '%s\n' "$value" ;;
    *) printf '%s\n' "$dir/$value" ;;
  esac
}

ports_for_pid() {
  command -v ss >/dev/null 2>&1 || return 0
  ss -lntp 2>/dev/null | awk -v pid="$1" '
    $0 ~ ("pid=" pid ",") {
      n = split($4, parts, ":")
      port = parts[n]
      if (!seen[port]++) {
        out = (out ? out "," : "") port
      }
    }
    END {
      print out
    }
  '
}

primary_port() {
  local old_ifs
  local port

  old_ifs="$IFS"
  IFS=','
  set -- $1
  IFS="$old_ifs"

  for port in "$@"; do
    case "$port" in
      ''|*[!0-9]*) ;;
      90*|91*|92*|93*|94*|95*|96*|97*|98*|99*) ;;
      *) printf '%s\n' "$port"; return 0 ;;
    esac
  done

  printf '%s\n' "${1:-}"
}

find_java_pids() {
  local id
  local role
  local dir
  local match
  local pid
  local exe
  local cwd
  local cmd

  id="$1"
  role="$2"
  dir=$(component_dir "$id" "$role") || return 1
  match=$(component_match "$id" "$role") || return 1

  [ -n "$dir" ] || return 0
  command -v pgrep >/dev/null 2>&1 || return 0

  for pid in $(pgrep -f "$match" 2>/dev/null); do
    exe=$(basename "$(readlink -f "/proc/$pid/exe" 2>/dev/null || printf '')")
    [ "$exe" = "java" ] || continue

    cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || printf '')
    [ "$cwd" = "$dir" ] || continue

    cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || printf '')
    case "$cmd" in
      *"$match"*) printf '%s\n' "$pid" ;;
    esac
  done | sort -n
}

find_loop_pids() {
  local id
  local role
  local dir
  local loop
  local pid
  local exe
  local cwd
  local cmd

  id="$1"
  role="$2"
  dir=$(component_dir "$id" "$role") || return 1
  loop=$(component_loop "$id" "$role") || return 1

  [ -n "$dir" ] || return 0
  [ -n "$loop" ] || return 0
  command -v pgrep >/dev/null 2>&1 || return 0

  for pid in $(pgrep -f "$loop" 2>/dev/null); do
    exe=$(basename "$(readlink -f "/proc/$pid/exe" 2>/dev/null || printf '')")
    case "$exe" in
      bash|sh) ;;
      *) continue ;;
    esac

    cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || printf '')
    [ "$cwd" = "$dir" ] || continue

    cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || printf '')
    case "$cmd" in
      *"$loop"*) printf '%s\n' "$pid" ;;
    esac
  done | sort -n
}

component_status_text() {
  local id
  local role
  local pids
  local first_pid
  local ports
  local port
  local hint

  id="$1"
  role="$2"

  if ! component_enabled "$id" "$role"; then
    printf '%s\n' "DISABLED"
    return 0
  fi

  pids=$(find_java_pids "$id" "$role")
  if [ -z "$pids" ]; then
    printf '%s\n' "STOPPED"
    return 0
  fi

  first_pid=$(printf '%s\n' "$pids" | head -n 1)
  ports=$(ports_for_pid "$first_pid")
  port=$(primary_port "$ports")
  hint=$(component_port_hint "$id" "$role")
  [ -n "$port" ] || port="$hint"
  [ -n "$port" ] || port="-"
  printf '%s\n' "RUN $port (pid $first_pid)"
}

component_state() {
  case "$(component_status_text "$1" "$2")" in
    RUN*) printf '%s\n' "RUN" ;;
    STOPPED) printf '%s\n' "STOPPED" ;;
    DISABLED) printf '%s\n' "DISABLED" ;;
    *) printf '%s\n' "UNKNOWN" ;;
  esac
}

run_as_owner() {
  local owner
  local dir
  local loop

  owner="$1"
  dir="$2"
  loop="$3"

  if [ "$owner" = "root" ] || [ "$(id -un)" = "$owner" ]; then
    (
      cd "$dir" && nohup "./$loop" >/dev/null 2>&1 < /dev/null &
    )
  else
    su - "$owner" -s /bin/bash -c "cd '$dir' && nohup './$loop' >/dev/null 2>&1 < /dev/null &"
  fi
}

start_component() {
  local id
  local role
  local dir
  local loop
  local owner
  local pids

  id="$1"
  role="$2"

  component_enabled "$id" "$role" || {
    printf '%s/%s is disabled\n' "$id" "$role"
    return 1
  }

  dir=$(component_dir "$id" "$role") || return 1
  loop=$(component_loop "$id" "$role") || return 1
  owner=$(server_owner "$id")

  pids=$(find_java_pids "$id" "$role")
  if [ -n "$pids" ]; then
    printf '%s/%s already running: %s\n' "$id" "$role" "$(component_status_text "$id" "$role")"
    return 0
  fi

  if [ ! -x "$dir/$loop" ]; then
    printf 'Cannot start %s/%s: missing executable %s/%s\n' "$id" "$role" "$dir" "$loop"
    return 1
  fi

  run_as_owner "$owner" "$dir" "$loop"
  sleep "$UNIX_L2_CP_START_WAIT"

  pids=$(find_java_pids "$id" "$role")
  if [ -n "$pids" ]; then
    printf 'Started %s/%s: %s\n' "$id" "$role" "$(component_status_text "$id" "$role")"
    return 0
  fi

  printf 'Start command sent for %s/%s, but process is not up yet. Check log: %s\n' \
    "$id" "$role" "$(component_log_path "$id" "$role")"
  return 1
}

stop_component() {
  local id
  local role
  local pids
  local loops
  local wait_left

  id="$1"
  role="$2"

  pids=$(find_java_pids "$id" "$role")
  loops=$(find_loop_pids "$id" "$role")

  if [ -z "$pids" ] && [ -z "$loops" ]; then
    printf '%s/%s already stopped\n' "$id" "$role"
    return 0
  fi

  if [ -n "$pids" ]; then
    kill -TERM $pids 2>/dev/null || true
  fi

  wait_left="$UNIX_L2_CP_STOP_TIMEOUT"
  while [ "$wait_left" -gt 0 ]; do
    pids=$(find_java_pids "$id" "$role")
    [ -z "$pids" ] && break
    sleep 1
    wait_left=$((wait_left - 1))
  done

  pids=$(find_java_pids "$id" "$role")
  if [ -n "$pids" ]; then
    printf 'Stop timeout for %s/%s. Still running: %s\n' "$id" "$role" "$pids"
    return 1
  fi

  loops=$(find_loop_pids "$id" "$role")
  if [ -n "$loops" ]; then
    kill -TERM $loops 2>/dev/null || true
    sleep 1
  fi

  printf 'Stopped %s/%s\n' "$id" "$role"
}

restart_component() {
  stop_component "$1" "$2" || return 1
  start_component "$1" "$2"
}

show_component_logs() {
  local id
  local role
  local lines
  local log_path

  id="$1"
  role="$2"
  lines="${3:-40}"
  log_path=$(component_log_path "$id" "$role") || return 1

  [ -f "$log_path" ] || {
    printf 'Log not found: %s\n' "$log_path"
    return 1
  }

  tail -n "$lines" "$log_path"
}

follow_component_logs() {
  local id
  local role
  local lines
  local log_path

  id="$1"
  role="$2"
  lines="${3:-40}"
  log_path=$(component_log_path "$id" "$role") || return 1

  [ -f "$log_path" ] || {
    printf 'Log not found: %s\n' "$log_path"
    return 1
  }

  tail -n "$lines" -f "$log_path"
}
