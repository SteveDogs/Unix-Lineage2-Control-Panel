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

maintenance_dir() {
  printf '%s\n' "$UNIX_L2_CP_STATE_DIR/maintenance"
}

maintenance_flag_path() {
  printf '%s/%s.flag\n' "$(maintenance_dir)" "$1"
}

ensure_state_dirs() {
  mkdir -p "$(maintenance_dir)"
}

maintenance_is_on() {
  [ -f "$(maintenance_flag_path "$1")" ]
}

server_mode_text() {
  if maintenance_is_on "$1"; then
    printf '%s\n' "MAINT"
  else
    printf '%s\n' "LIVE"
  fi
}

enable_maintenance_flag() {
  ensure_state_dirs
  date '+%Y-%m-%d %H:%M:%S' > "$(maintenance_flag_path "$1")"
}

disable_maintenance_flag() {
  rm -f "$(maintenance_flag_path "$1")"
}

file_mtime_epoch() {
  if [ ! -e "$1" ]; then
    printf '%s\n' "0"
    return 0
  fi

  stat -c %Y "$1" 2>/dev/null && return 0
  stat -f %m "$1" 2>/dev/null && return 0
  printf '%s\n' "0"
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

port_is_listening() {
  command -v ss >/dev/null 2>&1 || return 2
  ss -lnt 2>/dev/null | awk -v port="$1" '
    NR > 1 {
      n = split($4, parts, ":")
      if (parts[n] == port) {
        found = 1
      }
    }
    END {
      exit found ? 0 : 1
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

component_first_pid() {
  local pids

  pids=$(find_java_pids "$1" "$2")
  [ -n "$pids" ] || return 1
  printf '%s\n' "$pids" | head -n 1
}

component_current_port() {
  local pid
  local ports
  local port
  local hint

  pid=$(component_first_pid "$1" "$2") || return 1
  ports=$(ports_for_pid "$pid")
  port=$(primary_port "$ports")
  hint=$(component_port_hint "$1" "$2")

  [ -n "$port" ] || port="$hint"
  [ -n "$port" ] || return 1
  printf '%s\n' "$port"
}

component_status_text() {
  local id
  local role
  local pids
  local first_pid
  local port

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
  port=$(component_current_port "$id" "$role" 2>/dev/null || printf '%s' '-')
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

component_ready_now() {
  local id
  local role
  local started_at
  local pid
  local expected_port
  local log_path
  local log_mtime
  local ready_match

  id="$1"
  role="$2"
  started_at="$3"

  pid=$(component_first_pid "$id" "$role") || return 1

  expected_port=$(component_port_hint "$id" "$role")
  if [ -n "$expected_port" ]; then
    port_is_listening "$expected_port" >/dev/null 2>&1 || return 1
  fi

  log_path=$(component_log_path "$id" "$role") || return 1
  [ -f "$log_path" ] || return 1
  log_mtime=$(file_mtime_epoch "$log_path")
  [ "$log_mtime" -ge "$started_at" ] || return 1

  ready_match=$(component_ready_match "$id" "$role")
  if [ -n "$ready_match" ]; then
    tail -n "$UNIX_L2_CP_READY_LOG_LINES" "$log_path" 2>/dev/null | grep -Fq "$ready_match" || return 1
  fi

  return 0
}

print_start_report() {
  local id
  local role
  local started_at
  local pid
  local expected_port
  local current_port
  local log_path
  local log_mtime
  local ready_match
  local result

  id="$1"
  role="$2"
  started_at="$3"
  result=0

  pid=$(component_first_pid "$id" "$role" 2>/dev/null || printf '')
  if [ -n "$pid" ]; then
    printf '  process : OK (pid %s)\n' "$pid"
  else
    printf '  process : FAIL\n'
    result=1
  fi

  expected_port=$(component_port_hint "$id" "$role")
  current_port=$(component_current_port "$id" "$role" 2>/dev/null || printf '')
  if [ -n "$expected_port" ]; then
    if port_is_listening "$expected_port" >/dev/null 2>&1; then
      printf '  port    : OK (%s)\n' "$expected_port"
    else
      printf '  port    : FAIL (expected %s, current %s)\n' "$expected_port" "${current_port:--}"
      result=1
    fi
  elif [ -n "$current_port" ]; then
    printf '  port    : OK (%s)\n' "$current_port"
  else
    printf '  port    : SKIP\n'
  fi

  log_path=$(component_log_path "$id" "$role" 2>/dev/null || printf '')
  if [ -n "$log_path" ] && [ -f "$log_path" ]; then
    log_mtime=$(file_mtime_epoch "$log_path")
    if [ "$log_mtime" -ge "$started_at" ]; then
      printf '  log     : OK (%s updated)\n' "$log_path"
    else
      printf '  log     : FAIL (%s did not change)\n' "$log_path"
      result=1
    fi
  else
    printf '  log     : FAIL (%s)\n' "${log_path:-missing}"
    result=1
  fi

  ready_match=$(component_ready_match "$id" "$role")
  if [ -n "$ready_match" ]; then
    if [ -f "$log_path" ] && tail -n "$UNIX_L2_CP_READY_LOG_LINES" "$log_path" 2>/dev/null | grep -Fq "$ready_match"; then
      printf '  ready   : OK (%s)\n' "$ready_match"
    else
      printf '  ready   : FAIL (%s)\n' "$ready_match"
      result=1
    fi
  else
    printf '  ready   : SKIP\n'
  fi

  return "$result"
}

wait_for_component_ready() {
  local id
  local role
  local started_at
  local wait_left

  id="$1"
  role="$2"
  started_at="$3"
  wait_left="$UNIX_L2_CP_START_VERIFY_WAIT"

  while [ "$wait_left" -gt 0 ]; do
    if component_ready_now "$id" "$role" "$started_at"; then
      print_start_report "$id" "$role" "$started_at"
      return 0
    fi
    sleep 1
    wait_left=$((wait_left - 1))
  done

  print_start_report "$id" "$role" "$started_at"
  return 1
}

start_component() {
  local id
  local role
  local dir
  local loop
  local owner
  local pids
  local started_at

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

  started_at=$(date +%s)
  run_as_owner "$owner" "$dir" "$loop"
  sleep "$UNIX_L2_CP_START_WAIT"

  if wait_for_component_ready "$id" "$role" "$started_at"; then
    printf 'Started %s/%s: %s\n' "$id" "$role" "$(component_status_text "$id" "$role")"
    return 0
  fi

  printf 'Start checks are incomplete for %s/%s. Current status: %s\n' \
    "$id" "$role" "$(component_status_text "$id" "$role")"
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

maintenance_on_server() {
  local id
  local rc

  id="$1"
  rc=0

  enable_maintenance_flag "$id"
  if component_enabled "$id" login; then
    stop_component "$id" login || rc=1
  fi
  if component_enabled "$id" game; then
    stop_component "$id" game || rc=1
  fi

  printf 'Maintenance enabled for %s\n' "$id"
  return "$rc"
}

maintenance_off_server() {
  local id
  local rc

  id="$1"
  rc=0

  if component_enabled "$id" login; then
    start_component "$id" login || rc=1
  fi
  if [ "$rc" -eq 0 ] && component_enabled "$id" game; then
    start_component "$id" game || rc=1
  fi

  if [ "$rc" -eq 0 ]; then
    disable_maintenance_flag "$id"
    printf 'Maintenance disabled for %s\n' "$id"
    return 0
  fi

  printf 'Maintenance is still enabled for %s because start checks failed\n' "$id"
  return 1
}

maintenance_status_server() {
  if maintenance_is_on "$1"; then
    printf '%s\n' "ON"
  else
    printf '%s\n' "OFF"
  fi
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
