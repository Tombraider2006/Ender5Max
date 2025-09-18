#!/bin/sh
cd /usr/data || exit

# Скачиваем архив fix_ender5_v5.1 с GitHub
wget --no-check-certificate -O fix_ender5_v5.1.zip https://github.com/Tombraider2006/Ender5Max/raw/main/fix_ender5_v5.1.zip

# Распаковываем архив
unzip -o fix_ender5_v5.1.zip -d /usr/data/
chmod +x /usr/data/fix_ender5_v5.1/*.sh

# Запускаем основное меню
cd /usr/data/fix_ender5_v5.1 || exit
./main.sh

# Чистим за собой
rm -f /usr/data/start_fix.sh
rm -f /usr/data/fix_ender5_v5.1.zip

