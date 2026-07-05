# Unix Lineage2 Control Panel

Простая консольная панель для управления `login` и `game` процессами Lineage 2 на Unix/Linux.

Автор: Steve Dog  
Сайт: [steve.dog](https://steve.dog)

## Для чего нужен проект

Если на сервере запущено несколько Lineage 2 сборок, обычный `ps ax` быстро превращается в кашу.  
Этот проект делает понятную панель и команды:

- краткий статус по серверам
- полный список процессов
- запуск
- остановка
- перезапуск
- просмотр логов
- диагностика перед первым запуском

## Установка

```bash
git clone https://github.com/SteveDogs/Unix-Lineage2-Control-Panel.git
cd Unix-Lineage2-Control-Panel
sudo ./install.sh
```

После установки появятся команды:

```bash
l2
l2ctl
l2ps
l2doctor
```

## Настройка

1. Скопируйте пример настроек:

```bash
sudo cp config/settings.conf.example /etc/unix-l2-control-panel/settings.conf
```

2. Скопируйте пример сервера:

```bash
sudo cp config/servers.d/example.conf /etc/unix-l2-control-panel/servers.d/myserver.conf
```

3. Отредактируйте файл и укажите свои пути:

```bash
sudo nano /etc/unix-l2-control-panel/servers.d/myserver.conf
```

## Основные команды

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

## Формат конфига

Пример:

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

## Языки

Панель поддерживает:

- русский
- английский
- украинский

Язык можно задать через:

```bash
UNIX_L2_CP_LANG=ru l2
UNIX_L2_CP_LANG=en l2
UNIX_L2_CP_LANG=uk l2
```
