# Unix Lineage2 Control Panel

Simple terminal control panel for Lineage 2 login and game server processes on Unix/Linux.

Created by Steve Dog  
Website: [steve.dog](https://steve.dog)

## Languages

- [Russian](docs/README.ru.md)
- [English](docs/README.en.md)
- [Ukrainian](docs/README.uk.md)

## What it does

- Shows clean server status instead of messy `ps ax` output
- Starts, stops, and restarts `login`, `game`, or both
- Opens logs and follows logs live
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
l2ctl start myserver game
l2ctl stop myserver login
l2ctl restart myserver both
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
