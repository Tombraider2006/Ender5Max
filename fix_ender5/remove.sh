#!/bin/sh
set -u

HELPER_DIR="/usr/data/helper"

show_header() {
  clear
  echo "[УДАЛЕНИЕ]"
  echo "[1] Удалить Moonraker"
  echo "[2] Удалить Fluidd"
  echo "[3] Удалить Mainsail"
  echo "[4] Удалить Entware"
  echo "[5] Выключить Klipper Gcode Shell Command"
  echo "[6] Удалить Improved Shapers Calibrations"
  echo "[7] Откатить исправления Ender-5 Max"
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
    1) if confirm_action; then "$HELPER_DIR/scripts/moonraker_nginx.sh" remove; read -p "Нажмите Enter..."; fi;;
    2) if confirm_action; then "$HELPER_DIR/scripts/fluidd.sh" remove; read -p "Нажмите Enter..."; fi;;
    3) if confirm_action; then "$HELPER_DIR/scripts/mainsail.sh" remove; read -p "Нажмите Enter..."; fi;;
    4) if confirm_action; then "$HELPER_DIR/scripts/entware.sh" remove; read -p "Нажмите Enter..."; fi;;
    5) if confirm_action; then "$HELPER_DIR/scripts/gcode_shell_command.sh" remove; read -p "Нажмите Enter..."; fi;;
    6) if confirm_action; then "$HELPER_DIR/scripts/improved_shapers.sh" remove; read -p "Нажмите Enter..."; fi;;
    7) if confirm_action; then ./e5m_fix.sh restore; fi;;
    b|B) exit 0 ;;
  esac
done
