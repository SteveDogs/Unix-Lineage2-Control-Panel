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
	date '+%Y-%m-%d %H:%M:%S' >"$(maintenance_flag_path "$1")"
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

port_listener_line() {
	local port

	port="$1"
	command -v ss >/dev/null 2>&1 || return 1
	ss -H -lntp 2>/dev/null | awk -v port="$port" '
    {
      endpoint = $4
      sub(/^.*:/, "", endpoint)
      if (endpoint == port) {
        print
        exit
      }
    }
  '
}

port_listener_pid() {
	local line

	line=$(port_listener_line "$1") || return 1
	printf '%s\n' "$line" | sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' | head -n 1
}

port_listener_info() {
	local port
	local pid
	local process

	port="$1"
	pid=$(port_listener_pid "$port" 2>/dev/null || printf '')
	if [ -n "$pid" ]; then
		process=$(ps -o comm= -p "$pid" 2>/dev/null | awk '{$1=$1; print}' || printf '')
		printf 'pid %s%s\n' "$pid" "${process:+, $process}"
	else
		printf '%s\n' "unknown process"
	fi
}

check_component_port_available() {
	local id
	local role
	local port

	id="$1"
	role="$2"
	port=$(component_port_hint "$id" "$role")
	[ -n "$port" ] || return 0
	command -v ss >/dev/null 2>&1 || return 0

	if port_is_listening "$port"; then
		printf 'Cannot start %s/%s: port %s is already in use (%s)\n' \
			"$id" "$role" "$port" "$(port_listener_info "$port")"
		return 1
	fi
}

primary_port() {
	local old_ifs
	local -a parts
	local port

	old_ifs="$IFS"
	IFS=','
	read -r -a parts <<<"$1"
	IFS="$old_ifs"

	for port in "${parts[@]}"; do
		case "$port" in
		'' | *[!0-9]*) ;;
		90* | 91* | 92* | 93* | 94* | 95* | 96* | 97* | 98* | 99*) ;;
		*)
			printf '%s\n' "$port"
			return 0
			;;
		esac
	done

	printf '%s\n' "${parts[0]:-}"
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

		cmd=$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null || printf '')
		case "$cmd" in
		*"$match"*) printf '%s\n' "$pid" ;;
		esac
	done | sort -n
}

find_aa_pids() {
	local id
	local dir
	local binary
	local pid
	local exe
	local cwd

	id="$1"
	dir=$(component_dir "$id" aa) || return 1
	binary=$(component_match "$id" aa) || return 1

	[ -n "$dir" ] || return 0
	command -v pgrep >/dev/null 2>&1 || return 0

	for pid in $(pgrep -f "$binary" 2>/dev/null); do
		exe=$(basename "$(readlink -f "/proc/$pid/exe" 2>/dev/null || printf '')")
		[ "$exe" = "$binary" ] || continue

		cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || printf '')
		[ "$cwd" = "$dir" ] || continue

		printf '%s\n' "$pid"
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
		bash | sh) ;;
		*) continue ;;
		esac

		cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || printf '')
		[ "$cwd" = "$dir" ] || continue

		cmd=$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null || printf '')
		case "$cmd" in
		*"$loop"*) printf '%s\n' "$pid" ;;
		esac
	done | sort -n
}

find_aa_loop_pids() {
	local id
	local dir
	local loop
	local pid
	local exe
	local cwd
	local cmd

	id="$1"
	dir=$(component_dir "$id" aa) || return 1
	loop=$(component_run_loop "$id" aa) || return 1

	[ -n "$dir" ] || return 0
	[ -n "$loop" ] || return 0
	command -v pgrep >/dev/null 2>&1 || return 0

	for pid in $(pgrep -f "$loop" 2>/dev/null); do
		exe=$(basename "$(readlink -f "/proc/$pid/exe" 2>/dev/null || printf '')")
		case "$exe" in
		bash | sh | dash) ;;
		*) continue ;;
		esac

		cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || printf '')
		[ "$cwd" = "$dir" ] || continue

		cmd=$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null || printf '')
		case "$cmd" in
		*"$loop"*) printf '%s\n' "$pid" ;;
		esac
	done | sort -n
}

find_component_pids() {
	case "$2" in
	aa) find_aa_pids "$1" ;;
	*) find_java_pids "$1" "$2" ;;
	esac
}

find_component_loop_pids() {
	case "$2" in
	aa) find_aa_loop_pids "$1" ;;
	*) find_loop_pids "$1" "$2" ;;
	esac
}

component_first_pid() {
	local pids

	pids=$(find_component_pids "$1" "$2")
	[ -n "$pids" ] || return 1
	printf '%s\n' "$pids" | head -n 1
}

component_cpu_percent() {
	local pids
	local pid
	local values

	pids=$(find_component_pids "$1" "$2")
	[ -n "$pids" ] || return 1
	values=""
	for pid in $pids; do
		values="${values}$(ps -o %cpu= -p "$pid" 2>/dev/null || printf '0')\n"
	done
	printf '%b' "$values" | awk '{sum += $1} END {printf "%.1f\n", sum}'
}

component_memory_kb() {
	local pids
	local pid
	local values

	pids=$(find_component_pids "$1" "$2")
	[ -n "$pids" ] || return 1
	values=""
	for pid in $pids; do
		values="${values}$(ps -o rss= -p "$pid" 2>/dev/null || printf '0')\n"
	done
	printf '%b' "$values" | awk '{sum += $1} END {printf "%.0f\n", sum}'
}

format_memory_kb() {
	awk -v kb="${1:-0}" 'BEGIN {
    if (kb >= 1048576) printf "%.1fG\n", kb / 1048576
    else if (kb >= 1024) printf "%.0fM\n", kb / 1024
    else printf "%.0fK\n", kb
  }'
}

format_duration() {
	local seconds
	local days
	local hours
	local minutes

	seconds="${1:-0}"
	case "$seconds" in
	'' | *[!0-9]*) seconds=0 ;;
	esac
	days=$((seconds / 86400))
	hours=$(((seconds % 86400) / 3600))
	minutes=$(((seconds % 3600) / 60))

	if [ "$days" -gt 0 ]; then
		printf '%dd%02dh\n' "$days" "$hours"
	elif [ "$hours" -gt 0 ]; then
		printf '%dh%02dm\n' "$hours" "$minutes"
	elif [ "$minutes" -gt 0 ]; then
		printf '%dm\n' "$minutes"
	else
		printf '%ds\n' "$seconds"
	fi
}

component_uptime() {
	local pid
	local seconds

	pid=$(component_first_pid "$1" "$2") || return 1
	seconds=$(ps -o etimes= -p "$pid" 2>/dev/null | awk '{$1=$1; print}')
	[ -n "$seconds" ] || return 1
	format_duration "$seconds"
}

component_port_check_text() {
	local id
	local role
	local port
	local pid
	local component_pids
	local current_ports
	local ports

	id="$1"
	role="$2"
	if ! component_enabled "$id" "$role"; then
		printf '%s\n' "DISABLED"
		return 0
	fi

	port=$(component_port_hint "$id" "$role")
	if [ -z "$port" ]; then
		printf '%s\n' "NOT SET"
		return 0
	fi
	if ! command -v ss >/dev/null 2>&1; then
		printf '%s\n' "NO SS"
		return 0
	fi
	component_pids=$(find_component_pids "$id" "$role")
	if ! port_is_listening "$port"; then
		if [ -n "$component_pids" ]; then
			current_ports=""
			for pid in $component_pids; do
				ports=$(ports_for_pid "$pid")
				[ -n "$ports" ] || continue
				current_ports="${current_ports}${current_ports:+,}${ports}"
			done
			printf 'MISMATCH running on %s\n' "${current_ports:--}"
			return 0
		fi
		printf '%s\n' "FREE"
		return 0
	fi

	pid=$(port_listener_pid "$port" 2>/dev/null || printf '')
	if [ -n "$pid" ] && printf '%s\n' "$component_pids" | grep -Fxq "$pid"; then
		printf 'OWN pid %s\n' "$pid"
	else
		printf 'BUSY %s\n' "$(port_listener_info "$port")"
	fi
}

component_current_port() {
	local pid
	local ports
	local port
	local hint

	pid=$(component_first_pid "$1" "$2") || return 1
	ports=$(ports_for_pid "$pid")
	hint=$(component_port_hint "$1" "$2")

	case ",$ports," in
	*",$hint,"*) port="$hint" ;;
	*) port=$(primary_port "$ports") ;;
	esac

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

	pids=$(find_component_pids "$id" "$role")
	if [ -z "$pids" ]; then
		printf '%s\n' "STOPPED"
		return 0
	fi

	first_pid=$(printf '%s\n' "$pids" | head -n 1)
	if [ "$role" = "aa" ]; then
		port=$(component_port_hint "$id" "$role")
		[ -n "$port" ] || port="-"
		printf '%s\n' "RUN $port (pid $first_pid)"
	else
		port=$(component_current_port "$id" "$role" 2>/dev/null || printf '%s' '-')
		printf '%s\n' "RUN $port (pid $first_pid)"
	fi
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
	local role

	owner="$1"
	dir="$2"
	loop="$3"
	role="${4:-}"

	if [ "$role" = "aa" ]; then
		if [ "$owner" = "root" ] || [ "$(id -un)" = "$owner" ]; then
			(
				cd "$dir" && nohup sh "./$loop" >/dev/null 2>&1 </dev/null &
			)
		else
			su - "$owner" -s /bin/bash -c "cd '$dir' && nohup sh './$loop' >/dev/null 2>&1 < /dev/null &"
		fi
	else
		if [ "$owner" = "root" ] || [ "$(id -un)" = "$owner" ]; then
			(
				cd "$dir" && nohup "./$loop" >/dev/null 2>&1 </dev/null &
			)
		else
			su - "$owner" -s /bin/bash -c "cd '$dir' && nohup './$loop' >/dev/null 2>&1 < /dev/null &"
		fi
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
	local service
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
	service=$(component_service "$id" "$role")

	pids=$(find_component_pids "$id" "$role")
	if [ -n "$pids" ]; then
		printf '%s/%s already running: %s\n' "$id" "$role" "$(component_status_text "$id" "$role")"
		return 0
	fi

	check_component_port_available "$id" "$role" || return 1

	if [ -n "$service" ]; then
		if ! command -v systemctl >/dev/null 2>&1 || ! systemctl cat "$service" >/dev/null 2>&1; then
			printf 'Cannot start %s/%s: systemd service not found: %s\n' "$id" "$role" "$service"
			return 1
		fi
	elif [ "$role" = "aa" ]; then
		if [ ! -f "$dir/$loop" ]; then
			printf 'Cannot start %s/%s: missing start script %s/%s\n' "$id" "$role" "$dir" "$loop"
			return 1
		fi
	else
		if [ ! -x "$dir/$loop" ]; then
			printf 'Cannot start %s/%s: missing executable %s/%s\n' "$id" "$role" "$dir" "$loop"
			return 1
		fi
	fi

	started_at=$(date +%s)
	if [ -n "$service" ]; then
		systemctl start "$service" || {
			printf 'Cannot start %s/%s: systemctl start %s failed\n' "$id" "$role" "$service"
			return 1
		}
	else
		run_as_owner "$owner" "$dir" "$loop" "$role"
	fi
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
	local -a pid_list
	local -a loop_list
	local screen_name
	local service
	local service_active
	local wait_left

	id="$1"
	role="$2"
	service=$(component_service "$id" "$role")
	service_active=0
	if [ -n "$service" ] && command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$service"; then
		service_active=1
	fi

	pids=$(find_component_pids "$id" "$role")
	loops=$(find_component_loop_pids "$id" "$role")

	if [ -z "$pids" ] && [ -z "$loops" ] && [ "$service_active" -eq 0 ]; then
		printf '%s/%s already stopped\n' "$id" "$role"
		return 0
	fi

	if [ -n "$service" ]; then
		systemctl stop "$service" || {
			printf 'Cannot stop %s/%s: systemctl stop %s failed\n' "$id" "$role" "$service"
			return 1
		}
	elif [ "$role" = "aa" ]; then
		screen_name=$(component_screen_name "$id" aa)
		if [ -n "$screen_name" ] && command -v screen >/dev/null 2>&1; then
			screen -S "$screen_name" -X quit >/dev/null 2>&1 || true
		fi
	fi

	if [ -z "$service" ] && [ -n "$pids" ]; then
		mapfile -t pid_list <<<"$pids"
		kill -TERM "${pid_list[@]}" 2>/dev/null || true
	fi

	wait_left="$UNIX_L2_CP_STOP_TIMEOUT"
	while [ "$wait_left" -gt 0 ]; do
		pids=$(find_component_pids "$id" "$role")
		[ -z "$pids" ] && break
		sleep 1
		wait_left=$((wait_left - 1))
	done

	pids=$(find_component_pids "$id" "$role")
	if [ -n "$pids" ]; then
		printf 'Stop timeout for %s/%s. Still running: %s\n' "$id" "$role" "$pids"
		return 1
	fi

	loops=$(find_component_loop_pids "$id" "$role")
	if [ -z "$service" ] && [ -n "$loops" ]; then
		mapfile -t loop_list <<<"$loops"
		kill -TERM "${loop_list[@]}" 2>/dev/null || true
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
	if component_enabled "$id" aa; then
		stop_component "$id" aa || rc=1
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
	if [ "$rc" -eq 0 ] && component_enabled "$id" aa; then
		start_component "$id" aa || rc=1
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
