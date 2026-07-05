# Unix Lineage2 Control Panel

Simple terminal control panel for Lineage 2 login and game server processes on Unix/Linux.

Created by Steve Dog  
Website: [steve.dog](https://steve.dog)

Current release: `1.1.0`

## Languages

- [Russian](docs/README.ru.md)
- [English](docs/README.en.md)
- [Ukrainian](docs/README.uk.md)

## What it does

- Shows clean server status instead of messy `ps ax` output
- Shows colored status with live and maintenance modes
- Starts, stops, and restarts `login`, `game`, or both
- Supports mass actions for all configured servers
- Supports maintenance mode for single or all servers
- Verifies PID, port, log activity, and ready text after start
- Opens logs and follows logs live
- Shows a separate server card with paths, logs, ports, and PIDs
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
l2ctl full
l2ctl card myserver
l2ctl start myserver game
l2ctl restart all login
l2ctl maintenance myserver on
l2ctl maintenance all status
l2ctl stop myserver login
l2ctl logs myserver game 50
l2ctl follow myserver login 100
l2doctor
```

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
