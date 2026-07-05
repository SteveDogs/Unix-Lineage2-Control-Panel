# Unix Lineage2 Control Panel

Проста консольна панель для керування `login` та `game` процесами Lineage 2 на Unix/Linux.

Автор: Steve Dog  
Сайт: [steve.dog](https://steve.dog)

## Для чого потрібен проєкт

Коли на одному сервері працює кілька збірок Lineage 2, звичайний `ps ax` стає незручним.  
Цей проєкт дає зрозуміле меню та прості команди для:

- короткого статусу
- повного списку процесів
- запуску
- зупинки
- перезапуску
- перегляду логів
- діагностики перед першим запуском

## Встановлення

```bash
git clone https://github.com/SteveDogs/Unix-Lineage2-Control-Panel.git
cd Unix-Lineage2-Control-Panel
sudo ./install.sh
```

Після встановлення будуть команди:

```bash
l2
l2ctl
l2ps
l2doctor
```

## Налаштування

1. Скопіюйте приклад налаштувань:

```bash
sudo cp config/settings.conf.example /etc/unix-l2-control-panel/settings.conf
```

2. Скопіюйте приклад сервера:

```bash
sudo cp config/servers.d/example.conf /etc/unix-l2-control-panel/servers.d/myserver.conf
```

3. Відредагуйте файл:

```bash
sudo nano /etc/unix-l2-control-panel/servers.d/myserver.conf
```

## Основні команди

```bash
l2ctl status
l2ctl full
l2ctl start myserver game
l2ctl stop myserver login
l2ctl restart myserver both
l2ctl logs myserver game 50
l2ctl follow myserver login 100
l2doctor
```

## Формат конфіга

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

GAME_ENABLED="true"
GAME_DIR="/home/games/gameserver"
GAME_LOOP="GameServer_loop.sh"
GAME_MATCH="GameServer"
GAME_LOG="log/stdout.log"
GAME_PORT_HINT="7777"
```

## Мови

Панель підтримує:

- російську
- англійську
- українську

Приклади:

```bash
UNIX_L2_CP_LANG=ru l2
UNIX_L2_CP_LANG=en l2
UNIX_L2_CP_LANG=uk l2
```
