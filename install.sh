#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="unix-l2-control-panel"
INSTALL_DIR="${INSTALL_DIR:-/opt/$PROJECT_NAME}"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"
CONFIG_DIR="${CONFIG_DIR:-/etc/unix-l2-control-panel}"
SERVER_DIR="$CONFIG_DIR/servers.d"
STATE_DIR="${STATE_DIR:-/var/lib/unix-l2-control-panel}"

if [ "$(id -u)" -ne 0 ]; then
	echo "Please run install.sh with sudo or as root."
	exit 1
fi

SRC_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$CONFIG_DIR" "$SERVER_DIR" "$STATE_DIR/maintenance"

cp -a "$SRC_DIR/README.md" "$INSTALL_DIR/"
cp -a "$SRC_DIR/LICENSE" "$INSTALL_DIR/"
cp -a "$SRC_DIR/CHANGELOG.md" "$INSTALL_DIR/"
cp -a "$SRC_DIR/CONTRIBUTING.md" "$INSTALL_DIR/"
cp -a "$SRC_DIR/bin" "$INSTALL_DIR/"
cp -a "$SRC_DIR/lib" "$INSTALL_DIR/"
cp -a "$SRC_DIR/docs" "$INSTALL_DIR/"
cp -a "$SRC_DIR/config" "$INSTALL_DIR/"

if [ ! -f "$CONFIG_DIR/settings.conf" ]; then
	cp "$SRC_DIR/config/settings.conf.example" "$CONFIG_DIR/settings.conf"
fi

if [ ! -f "$SERVER_DIR/example.conf.example" ]; then
	cp "$SRC_DIR/config/servers.d/example.conf" "$SERVER_DIR/example.conf.example"
fi

chmod +x "$INSTALL_DIR"/bin/*
chmod +x "$INSTALL_DIR/install.sh" 2>/dev/null || true

ln -sfn "$INSTALL_DIR/bin/l2" "$BIN_DIR/l2"
ln -sfn "$INSTALL_DIR/bin/l2menu" "$BIN_DIR/l2menu"
ln -sfn "$INSTALL_DIR/bin/l2ctl" "$BIN_DIR/l2ctl"
ln -sfn "$INSTALL_DIR/bin/l2ps" "$BIN_DIR/l2ps"
ln -sfn "$INSTALL_DIR/bin/l2doctor" "$BIN_DIR/l2doctor"

echo "Installed to $INSTALL_DIR"
echo "Config directory: $CONFIG_DIR"
echo "State directory: $STATE_DIR"
echo "Commands: l2, l2menu, l2ctl, l2ps, l2doctor"
