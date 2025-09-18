#!/bin/sh
set -u

PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"
PRINTER_BAK="${PRINTER_CFG}.bak"
MACRO_BAK="${MACRO_CFG}.bak"

show_header() {
  clear
  echo "========================================"
  echo "🚀 Tom Tomich Script (Ender-5 Max Fix)"
  echo "========================================"
  echo ""
}

check_status() {
  if [ -f "$PRINTER_BAK" ] && [ -f "$MACRO_BAK" ]; then
    FIXED=true
  else
    FIXED=false
  fi
}

apply_fix() {
  echo "⚙️ Применяются исправления..."
  cp -p "$PRINTER_CFG" "$PRINTER_BAK"
  cp -p "$MACRO_CFG" "$MACRO_BAK"

  # Удаляем старые секции
  sed -i '/\[firmware_retraction\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_shell_command beep\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_macro BEEP\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[delayed_gcode light_init\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[exclude_object\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_macro PID_BED\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_macro PID_HOTEND\]/,/^$/d' "$MACRO_CFG"

  # Добавляем новые секции
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

  echo "✅ Исправления применены."
  read -p "Нажмите Enter..."
}

restore_fix() {
  echo "♻️ Восстанавливаются файлы..."
  if [ -f "$PRINTER_BAK" ] && [ -f "$MACRO_BAK" ]; then
    cp -p "$PRINTER_BAK" "$PRINTER_CFG"
    cp -p "$MACRO_BAK" "$MACRO_CFG"
    rm -f "$PRINTER_BAK" "$MACRO_BAK"
    echo "✅ Исправления откатили."
  else
    echo "❗ Бэкапы не найдены."
  fi
  read -p "Нажмите Enter..."
}

while true; do
  show_header
  check_status
  echo "Меню:"
  if [ "$FIXED" = false ]; then
    echo -e "[1] \033[1;32mУстановить исправления\033[0m"
    echo -e "[2] \033[1;31mОткатить исправления (недоступно)\033[0m"
  else
    echo -e "[1] \033[1;31mУстановить исправления (уже установлены)\033[0m"
    echo -e "[2] \033[1;32mОткатить исправления\033[0m"
  fi
  echo -e "[3] Выйти\n"
  printf "Выберите действие: "
  read choice
  case "$choice" in
    1) if [ "$FIXED" = false ]; then
         printf "Вы уверены? (y/n): "
         read ans
         if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
           apply_fix
         fi
       fi;;
    2) if [ "$FIXED" = true ]; then
         restore_fix
       fi;;
    3) exit 0 ;;
  esac
done
