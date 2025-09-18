#!/bin/sh
cd /usr/data || exit

# Распаковать архив, если есть
if [ -f "/mnt/data/fix_ender5_v5.1.zip" ]; then
  unzip -o /mnt/data/fix_ender5_v5.1.zip -d /usr/data/
  chmod +x /usr/data/fix_ender5_v5.1/*.sh
fi

# Запустить основное меню
cd /usr/data/fix_ender5_v5.1 || exit
./main.sh
