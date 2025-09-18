#!/bin/sh
set -u

# ================================
#   Tom Tomich Script v4.1
#   Helper & Fix Tool for Ender-5 Max (Nebula Pad)
# ================================

YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"
PRINTER_BAK="${PRINTER_CFG}.bak"
MACRO_BAK="${MACRO_CFG}.bak"
HELPER_DIR="/usr/data/helper"

show_header() {
  clear
  printf "%b\n" "${YELLOW}========================================${RESET}"
  printf "%b\n" "${YELLOW}🚀 Tom Tomich Script v4.1 (Nebula Pad)${RESET}"
  printf "%b\n" "${YELLOW} Helper & Fix Tool for Ender-5 Max${RESET}"
  printf "%b\n" "${YELLOW}========================================${RESET}"
  echo ""
}

confirm_action() {
  printf "Вы уверены? (y/n): "
  read ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

prepare_helper() {
  if [ ! -d "$HELPER_DIR" ]; then
    printf "%b\n" "${YELLOW}📥 Скачиваем Helper Script...${RESET}"
    git clone https://github.com/Guilouz/Creality-Helper-Script.git "$HELPER_DIR"
    if [ $? -ne 0 ]; then
      printf "%b\n" "${RED}❌ Ошибка загрузки Helper Script${RESET}"
      exit 1
    fi
  else
    printf "%b\n" "${YELLOW}🔄 Обновляем Helper Script...${RESET}"
    cd "$HELPER_DIR" || exit
    git pull
  fi

  if [ -f "$HELPER_DIR/scripts/tools.sh" ]; then
    . "$HELPER_DIR/scripts/tools.sh"
  fi
}

restart_klipper() {
  if command -v curl >/dev/null 2>&1; then
    curl -s -X POST "http://localhost:7125/printer/restart" && return
  fi
  echo "⚠️ Не удалось автоматически перезапустить Klipper."
}

# ---------- Исправления Ender-5 Max ----------
fix_e5m() {
  echo "⚙️ Применяются исправления Ender-5 Max..."
  cp -p "$PRINTER_CFG" "$PRINTER_BAK"
  cp -p "$MACRO_CFG" "$MACRO_BAK"
  echo "📂 Созданы бэкапы."

  sed -i '/\[firmware_retraction\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_shell_command beep\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_macro BEEP\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[delayed_gcode light_init\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[exclude_object\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_macro PID_BED\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_macro PID_HOTEND\]/,/^$/d' "$MACRO_CFG"

  cat >> "$MACRO_CFG" <<'EOF'

[firmware_retraction]
retract_length: 0.45
retract_speed: 30
unretract_extra_length: 0
unretract_speed: 30

[gcode_shell_command beep]
command: beep
timeout: 2
verbose: False

[gcode_macro BEEP]
description: Play a sound
gcode:
  RUN_SHELL_COMMAND CMD=beep

[delayed_gcode light_init]
initial_duration: 5.01
gcode:
  SET_PIN PIN=light_pin VALUE=1

[exclude_object]

[gcode_macro PID_BED]
gcode:
  PID_CALIBRATE HEATER=heater_bed TARGET={params.BED_TEMP|default(70)}
  SAVE_CONFIG

[gcode_macro PID_HOTEND]
description: Start Hotend PID
gcode:
  G90
  G28
  G1 Z10 F600
  M106 S255
  PID_CALIBRATE HEATER=extruder TARGET={params.HOTEND_TEMP|default(250)}
  M107
EOF

  echo "✅ Исправления для Ender-5 Max применены."
  restart_klipper
  read -p "Нажмите Enter..."
}

restore_e5m() {
  echo "♻️ Восстанавливаются бэкапы Ender-5 Max..."
  if [ -f "$PRINTER_BAK" ] && [ -f "$MACRO_BAK" ]; then
    cp -p "$PRINTER_BAK" "$PRINTER_CFG"
    cp -p "$MACRO_BAK" "$MACRO_CFG"
    rm -f "$PRINTER_BAK" "$MACRO_BAK"
    echo "📂 Конфиги восстановлены."
    restart_klipper
    echo "✅ Восстановление завершено."
  else
    echo "❗ Бэкапы не найдены."
  fi
  read -p "Нажмите Enter..."
}

# ----- Меню установки -----
menu_install() {
  while true; do
    show_header
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
    printf "Выберите действие: "
    read choice
    case "$choice" in
      1) if confirm_action; then sh "$HELPER_DIR/scripts/moonraker_nginx.sh"; fi;;
      2) if confirm_action; then sh "$HELPER_DIR/scripts/fluidd.sh"; fi;;
      3) if confirm_action; then sh "$HELPER_DIR/scripts/mainsail.sh"; fi;;
      4) if confirm_action; then sh "$HELPER_DIR/scripts/entware.sh"; fi;;
      5) if confirm_action; then sh "$HELPER_DIR/scripts/gcode_shell_command.sh"; fi;;
      6) if confirm_action; then sh "$HELPER_DIR/scripts/improved_shapers.sh"; fi;;
      8) if confirm_action; then fix_e5m; fi;;
      b|B) return ;;
    esac
  done
}

# ----- Меню удаления -----
menu_remove() {
  while true; do
    show_header
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
    printf "Выберите действие: "
    read choice
    case "$choice" in
      1) if confirm_action; then sh "$HELPER_DIR/scripts/moonraker_nginx.sh" remove; fi;;
      2) if confirm_action; then sh "$HELPER_DIR/scripts/fluidd.sh" remove; fi;;
      3) if confirm_action; then sh "$HELPER_DIR/scripts/mainsail.sh" remove; fi;;
      4) if confirm_action; then sh "$HELPER_DIR/scripts/entware.sh" remove; fi;;
      5) if confirm_action; then sh "$HELPER_DIR/scripts/gcode_shell_command.sh" remove; fi;;
      6) if confirm_action; then sh "$HELPER_DIR/scripts/improved_shapers.sh" remove; fi;;
      7) if confirm_action; then restore_e5m; fi;;
      b|B) return ;;
    esac
  done
}

# ----- Главное меню -----
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
    1) menu_install ;;
    2) menu_remove ;;
    q|Q) echo "Выход..." ; exit 0 ;;
  esac
done
