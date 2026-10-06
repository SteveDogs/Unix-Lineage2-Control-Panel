# Unix Lineage2 Control Panel

Simple terminal control panel for Lineage 2 login, game, and Active Anticheat processes on Unix/Linux.

Created by Steve Dog  
Website: [steve.dog](https://steve.dog)

Current release: `1.4.0`

## Languages

- [Russian](docs/README.ru.md)
- [English](docs/README.en.md)
- [Ukrainian](docs/README.uk.md)

## What it does

- Shows clean server status instead of messy `ps ax` output
- Shows colored status with live and maintenance modes
- Shows CPU, RAM, uptime, PID, and port usage for every running component
- Checks configured ports and blocks startup when another process owns the port
- Uses confirmation, countdown, dependency order, and startup checks for safe restarts
- Starts, stops, and restarts `login`, `game`, `aa`, or full stack
- Supports mass actions for all configured servers
- Supports maintenance mode for single or all servers
- Verifies PID, port, log activity, and ready text after start
- Opens logs and follows logs live
- Shows a separate server card with paths, logs, ports, and PIDs
- Supports separate Active Anticheat folders with `startscreen.sh`
- Supports optional systemd services for login, game, and AA
- Works with multiple Lineage 2 server folders
- Uses config files instead of hardcoded private paths
- Includes a simple interactive menu
- Includes a diagnostics command for first setup

## Quick start

```bash
git clone https://github.com/SteveDogs/Unix-Lineage2-Control-Panel.git
cd Unix-Lineage2-Control-Panel
sudo ./install.sh
sudo cp config/settings.conf.example /etc/unix-l2-control-panel/settings.conf
sudo cp config/servers.d/example.conf /etc/unix-l2-control-panel/servers.d/myserver.conf
sudo nano /etc/unix-l2-control-panel/servers.d/myserver.conf
l2
```

## Main commands

```bash
l2
l2ctl status
l2ctl monitor
l2ctl ports
l2ctl full
l2ctl card myserver
l2ctl start myserver aa
l2ctl start myserver full
l2ctl start myserver game
l2ctl restart all login --yes
l2ctl maintenance myserver on
l2ctl maintenance all status
l2ctl stop myserver login
l2ctl logs myserver aa 50
l2ctl logs myserver game 50
l2ctl follow myserver login 100
l2doctor
```

Interactive restarts ask for confirmation automatically. A direct `l2ctl restart` command requires typing `YES`; scripts can pass `--yes`. The countdown is configured with `UNIX_L2_CP_RESTART_COUNTDOWN` in `settings.conf`.

Port diagnostics use `FREE`, `OWN`, `BUSY`, and `MISMATCH`. `MISMATCH` means the component is running but not on its configured port.

## Project structure

```text
bin/      Executable commands
lib/      Shared bash logic
config/   Example configs
docs/     RU / EN / UK docs
```

## Config examples

Examples included in `config/servers.d/`:

- `example.conf`
- `lucera-classic.conf.example`
- `pwsoft.conf.example`
- `bootclasspath-aa.conf.example`

`bootclasspath-aa.conf.example` shows a setup where the game server uses Active Anticheat and the AA daemon runs from a separate `Server` folder.

## Active Anticheat

If your server uses Active Anticheat with a separate `Server` folder, fill the `AA_*` fields in your server config:

```bash
AA_ENABLED="true"
AA_DIR="/root/project/Server"
AA_START="startscreen.sh"
AA_LOOP="start.sh"
AA_BINARY="server"
AA_LOG="log.txt"
AA_PORT_HINT="11000"
AA_READY_MATCH="Listening to players on address"
AA_SCREEN_NAME="projectaa"
```

Notes:

- `AA_DIR` should point to the separate Anticheat server folder, not the game server folder.
- The panel starts AA through `sh startscreen.sh`, because this is the common launch style from the official Active Anticheat Linux manual.
- If your game server uses AA, keep `LD_PRELOAD=$PWD/active_pr64.so` in the game start script as described in the [official manual](https://active-ac.com/manual/ru/lineage2/install_linux/).

## systemd services

If a component is managed by systemd, add its service name to the server config:

```bash
LOGIN_SERVICE="my-login.service"
GAME_SERVICE="my-game.service"
```

You can also use `AA_SERVICE`. Leave these fields empty when the component is managed by its usual start script.
