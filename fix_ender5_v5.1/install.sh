#!/bin/sh
set -u

HELPER_DIR="/usr/data/helper"

show_header() {
  clear
  echo "[УСТАНОВКА]"
  echo "[1] Установить Moonraker"
  echo "[2] Установить Fluidd"
  echo "[3] Установить Mainsail"
  echo "[4] Установить Entware"
  echo "[5] Включить Klipper Gcode Shell Command"
  echo "[6] Установить Improved Shapers Calibrations"
  echo "[8] Исправления конфигов для Ender-5 Max"
  echo "[b] Назад в главное меню"
  echo ""
}

confirm_action() {
  printf "Вы уверены? (y/n): "
  read ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

while true; do
  show_header
  printf "Выберите действие: "
  read choice
  case "$choice" in
    1) if confirm_action; then "$HELPER_DIR/scripts/moonraker_nginx.sh"; read -p "Нажмите Enter..."; fi;;
    2) if confirm_action; then "$HELPER_DIR/scripts/fluidd.sh"; read -p "Нажмите Enter..."; fi;;
    3) if confirm_action; then "$HELPER_DIR/scripts/mainsail.sh"; read -p "Нажмите Enter..."; fi;;
    4) if confirm_action; then "$HELPER_DIR/scripts/entware.sh"; read -p "Нажмите Enter..."; fi;;
    5) if confirm_action; then "$HELPER_DIR/scripts/gcode_shell_command.sh"; read -p "Нажмите Enter..."; fi;;
    6) if confirm_action; then "$HELPER_DIR/scripts/improved_shapers.sh"; read -p "Нажмите Enter..."; fi;;
    8) if confirm_action; then ./e5m_fix.sh fix; fi;;
    b|B) exit 0 ;;
  esac
done
