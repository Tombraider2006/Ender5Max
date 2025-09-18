#!/bin/sh
set -u

PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"
PRINTER_BAK="${PRINTER_CFG}.bak"
MACRO_BAK="${MACRO_CFG}.bak"

restart_klipper() {
  if command -v curl >/dev/null 2>&1; then
    curl -s -X POST "http://localhost:7125/printer/restart" && return
  fi
  echo "⚠️ Не удалось автоматически перезапустить Klipper."
}

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
}

case "$1" in
  fix) fix_e5m ;;
  restore) restore_e5m ;;
esac
