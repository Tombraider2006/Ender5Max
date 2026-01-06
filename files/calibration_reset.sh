#!/bin/bash

# Явно задаём UTF-8
export LANG=ru_RU.UTF-8
export LC_ALL=ru_RU.UTF-8

FILE="/usr/data/guppyscreen/calibration.json"
BACKUP="/usr/data/guppyscreen/calibration.json.bak"

# Проверяем, существует ли файл
if [ -f "$FILE" ]; then
    mv "$FILE" "$BACKUP"
fi

# Сообщение перед перезагрузкой
echo "иди жми крестики"

# Небольшая пауза, чтобы сообщение успели увидеть
sleep 2

# Перезагрузка
reboot
