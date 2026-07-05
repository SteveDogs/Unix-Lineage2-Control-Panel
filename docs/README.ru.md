# Unix Lineage2 Control Panel

Простая консольная панель для управления `login` и `game` процессами Lineage 2 на Unix/Linux.

Автор: Steve Dog  
Сайт: [steve.dog](https://steve.dog)

## Для чего нужен проект

Если на сервере запущено несколько Lineage 2 сборок, обычный `ps ax` быстро превращается в кашу.  
Этот проект делает понятную панель и команды:

- краткий статус по серверам
- цветной статус с режимами LIVE и MAINT
- полный список процессов
- карточка сервера с путями, PID, портами и логами
- запуск
- остановка
- перезапуск
- массовые действия по всем серверам
- режим обслуживания
- просмотр логов
- проверки после запуска: PID, порт, лог, ready text
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
LOGIN_READY_MATCH=""

GAME_ENABLED="true"
GAME_DIR="/home/games/gameserver"
GAME_LOOP="GameServer_loop.sh"
GAME_MATCH="GameServer"
GAME_LOG="log/stdout.log"
GAME_PORT_HINT="7777"
GAME_READY_MATCH=""
```

`LOGIN_READY_MATCH` и `GAME_READY_MATCH` можно оставить пустыми или указать текст из лога, по которому панель поймет, что сервер действительно поднялся.

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
