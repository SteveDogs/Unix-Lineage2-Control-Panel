#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="unix-l2-control-panel"
INSTALL_DIR="${INSTALL_DIR:-/opt/$PROJECT_NAME}"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"
CONFIG_DIR="${CONFIG_DIR:-/etc/unix-l2-control-panel}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run uninstall.sh with sudo or as root."
  exit 1
fi

rm -f "$BIN_DIR/l2" "$BIN_DIR/l2ctl" "$BIN_DIR/l2ps" "$BIN_DIR/l2doctor"

if [ "${1:-}" = "--purge" ]; then
  rm -rf "$INSTALL_DIR" "$CONFIG_DIR"
  echo "Removed binaries, install dir, and config dir."
else
  rm -rf "$INSTALL_DIR"
  echo "Removed binaries and install dir."
  echo "Config directory was kept: $CONFIG_DIR"
fi
