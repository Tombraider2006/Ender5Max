#!/bin/sh
set -u

HELPER_DIR="/usr/data/helper"

show_header() {
  clear
  echo "========================================"
  echo "🚀 Tom Tomich Script v5.1 (Nebula Pad)"
  echo " Helper & Fix Tool for Ender-5 Max"
  echo "========================================"
  echo ""
}

prepare_self() {
  if [ ! -d "/usr/data/fix_ender5_v5.1" ]; then
    echo "📥 Скачиваем fix_ender5_v5.1 из GitHub..."
    cd /usr/data || exit
    wget -q https://github.com/Tombraider2006/Ender5Max/archive/refs/heads/main.zip -O main.zip
    unzip -q main.zip "Ender5Max-main/fix_ender5_v5.1/*" -d .
    mv Ender5Max-main/fix_ender5_v5.1 ./fix_ender5_v5.1
    rm -rf Ender5Max-main main.zip
    chmod +x fix_ender5_v5.1/*.sh
    cd fix_ender5_v5.1 || exit
    echo "✅ fix_ender5_v5.1 установлен."
  fi
}

prepare_helper() {
  if [ ! -d "$HELPER_DIR" ]; then
    echo "📥 Скачиваем Helper Script..."
    git clone https://github.com/Guilouz/Creality-Helper-Script.git "$HELPER_DIR"
    if [ $? -ne 0 ]; then
      echo "❌ Ошибка загрузки Helper Script"
      exit 1
    fi
  else
    echo "🔄 Обновляем Helper Script..."
    cd "$HELPER_DIR" || exit
    git pull
    cd - >/dev/null
  fi

  chmod +x "$HELPER_DIR/scripts/"*.sh 2>/dev/null
}

prepare_self
prepare_helper

while true; do
  show_header
  echo "[1] УСТАНОВКА"
  echo "[2] УДАЛЕНИЕ"
  echo "[q] Выйти"
  echo ""
  printf "Выберите действие: "
  read choice
  case "$choice" in
    1) ./install.sh ;;
    2) ./remove.sh ;;
    q|Q) echo "Выход..." ; exit 0 ;;
  esac
done
