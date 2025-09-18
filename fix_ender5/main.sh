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
