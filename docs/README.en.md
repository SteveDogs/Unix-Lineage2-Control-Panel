# Unix Lineage2 Control Panel

Simple terminal control panel for `login`, `game`, and `AA` Lineage 2 processes on Unix/Linux.

Created by Steve Dog  
Website: [steve.dog](https://steve.dog)

## Why this project exists

When several Lineage 2 server packs run on one machine, plain `ps ax` becomes hard to read.  
This project gives you a clean menu and simple commands for:

- short status
- colored status with LIVE and MAINT modes
- full process list
- server card with paths, logs, ports, and PIDs
- start
- stop
- restart
- Active Anticheat support with separate folder and `startscreen.sh`
- mass actions for all configured servers
- maintenance mode
- log viewing
- post-start checks: PID, port, log activity, and ready text
- setup diagnostics

## Installation

```bash
git clone https://github.com/SteveDogs/Unix-Lineage2-Control-Panel.git
cd Unix-Lineage2-Control-Panel
sudo ./install.sh
```

Commands after install:

```bash
l2
l2ctl
l2ps
l2doctor
```

## Setup

1. Copy settings:

```bash
sudo cp config/settings.conf.example /etc/unix-l2-control-panel/settings.conf
```

2. Copy a server example:

```bash
sudo cp config/servers.d/example.conf /etc/unix-l2-control-panel/servers.d/myserver.conf
```

3. Edit the file:

```bash
sudo nano /etc/unix-l2-control-panel/servers.d/myserver.conf
```

## Main commands

```bash
l2ctl status
l2ctl full
l2ctl card myserver
l2ctl start myserver aa
l2ctl start myserver full
l2ctl start myserver game
l2ctl restart all login
l2ctl maintenance myserver on
l2ctl maintenance all status
l2ctl stop myserver login
l2ctl logs myserver aa 50
l2ctl logs myserver game 50
l2ctl follow myserver login 100
l2doctor
```

## Config format

```bash
SERVER_ID="myserver"
SERVER_NAME="My Server"
SERVER_OWNER="games"

LOGIN_ENABLED="true"
LOGIN_DIR="/home/games/loginserver"
LOGIN_LOOP="AuthServer_loop.sh"
LOGIN_MATCH="AuthServer"
LOGIN_LOG="log/stdout.log"
LOGIN_PORT_HINT="2106"
LOGIN_READY_MATCH=""

AA_ENABLED="false"
AA_DIR="/home/games/anticheat"
AA_START="startscreen.sh"
AA_LOOP="start.sh"
AA_BINARY="server"
AA_LOG="log.txt"
AA_PORT_HINT="11000"
AA_READY_MATCH="Listening to players on address"
AA_SCREEN_NAME="myserver-aa"

GAME_ENABLED="true"
GAME_DIR="/home/games/gameserver"
GAME_LOOP="GameServer_loop.sh"
GAME_MATCH="GameServer"
GAME_LOG="log/stdout.log"
GAME_PORT_HINT="7777"
GAME_READY_MATCH=""
```

`LOGIN_READY_MATCH`, `AA_READY_MATCH`, and `GAME_READY_MATCH` can stay empty or contain a log line that means the server is fully started.

## Active Anticheat

If your setup uses a separate `Server` folder for Active Anticheat, fill the `AA_*` fields in the server config.

- `AA_DIR` should point to the Anticheat folder, not to the game server folder.
- The panel starts AA through `sh startscreen.sh`, because this is the standard launch style from the [official Active Anticheat Linux manual](https://active-ac.com/manual/ru/lineage2/install_linux/).
- If your game server uses Active Anticheat, keep `LD_PRELOAD=$PWD/active_pr64.so` in the game server start script.

## Languages

The menu supports:

- Russian
- English
- Ukrainian

Examples:

```bash
UNIX_L2_CP_LANG=ru l2
UNIX_L2_CP_LANG=en l2
UNIX_L2_CP_LANG=uk l2
```
