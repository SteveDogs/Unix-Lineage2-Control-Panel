# Changelog

## 1.4.0

- Added a redesigned dashboard with live server status and host information.
- Added component CPU, RAM, uptime, PID, and port monitoring.
- Added configured port diagnostics and automatic conflict checks before startup.
- Added safe restart confirmation, countdown, dependency order, and startup verification.

## 1.3.0

- Added optional systemd service control for login, game, and AA components.
- Server cards and diagnostics now show configured service names.
- Kept the existing script-based process control fully compatible.

## 1.2.0

- Added Active Anticheat support with separate `AA` status, logs, and diagnostics.
- Added support for `startscreen.sh` and `start.sh` in AA server folders.
- Added AA fields to config examples and documentation.
- Improved server card and full process view for AA setups.

## 1.1.0

- Added `all` actions for `start`, `stop`, and `restart`.
- Added maintenance mode with `on`, `off`, and `status`.
- Added post-start checks for PID, port, log activity, and optional ready text.
- Added colored short status output.
- Added server card view.
- Added more config examples and updated docs.

## 1.0.0

- First public release.
- Added config-based `login/game` control.
- Added interactive terminal menu.
- Added diagnostics command.
- Added documentation in Russian, English, and Ukrainian.
