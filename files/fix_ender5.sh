#!/bin/bash
set -u

# ================================
#   Tom Tomich Script v1.0
#   Fix & Patch tool for Ender-5 Max
# ================================

# Цвета
BLUE="\033[1;34m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# Пути к конфигам
PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"
PRINTER_BAK="${PRINTER_CFG}.bak"
MACRO_BAK="${MACRO_CFG}.bak"

# --- Функция: показать шапку ---
show_header() {
  clear
  echo -e "${BLUE}#############################################${RESET}"
  echo -e "${BLUE}#                                           #${RESET}"
  echo -e "${BLUE}#         🚀 Tom Tomich Script v1.0         #${RESET}"
  echo -e "${BLUE}#   Fix & Patch tool for Ender-5 Max        #${RESET}"
  echo -e "${BLUE}#                                           #${RESET}"
  echo -e "${BLUE}#   Author : Tom Tomich                     #${RESET}"
  echo -e "${BLUE}#   Purpose: Автоматизация правок           #${RESET}"
  echo -e "${BLUE}#            printer.cfg и gcode_macro.cfg  #${RESET}"
  echo -e "${BLUE}#                                           #${RESET}"
  echo -e "${BLUE}#############################################${RESET}"
  echo ""
}

apply_fixes() {
  cp -p "$PRINTER_CFG" "$PRINTER_BAK"
  cp -p "$MACRO_CFG" "$MACRO_BAK"
  echo -e "${YELLOW}📂 Созданы бэкапы:${RESET}"
  echo -e "   $PRINTER_BAK"
  echo -e "   $MACRO_BAK"

  # --- printer.cfg ---
  sed -i 's/^\[output_pin Height_module2\]/[output_pin _Height_module2]/' "$PRINTER_CFG"
  for pat in "output_pin light_pin" "output_pin MainBoardFan" \
             "output_pin fan0" "output_pin en_fan0" "output_pin fan1" "output_pin en_fan1" \
             "multi_pin part_fans" "multi_pin en_part_fans" "fan_generic part" "controller_fan MCU_fan"
  do
    sed -i "/^\[$pat\]/,/^$/d" "$PRINTER_CFG"
    sed -i "/^\[$pat\]/,/^\[/d" "$PRINTER_CFG"
  done

  cat <<'EOF' >> "$PRINTER_CFG"

[output_pin light_pin] # освещение камеры принтера. косяк прошивки креалити.
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0

[controller_fan MCU_fan] # включаем обдув после включения драйверов
pin: PB1
max_power: 1.0
fan_speed: 1
kick_start_time: 0
stepper: stepper_x

[multi_pin part_fans]
pins:!nozzle_mcu:PB15,!nozzle_mcu:PA9

[multi_pin en_part_fans]
pins:nozzle_mcu:PB6,nozzle_mcu:PB9

[fan_generic part]
pin: multi_pin:part_fans
enable_pin: multi_pin:en_part_fans
cycle_time: 0.0100
hardware_pwm: false
EOF

  # --- gcode_macro.cfg ---
  for pat in "gcode_macro M106" "gcode_macro M107" "gcode_macro TURN_OFF_FANS" "gcode_macro TURN_ON_FANS" \
             "firmware_retraction" "gcode_shell_command beep" "gcode_macro BEEP" \
             "delayed_gcode light_init" "exclude_object" "gcode_macro PID_BED" "gcode_macro PID_HOTEND"
  do
    sed -i "/^\[$pat\]/,/^$/d" "$MACRO_CFG"
    sed -i "/^\[$pat\]/,/^\[/d" "$MACRO_CFG"
  done
  sed -i '/^variable_fan0_min:/d' "$MACRO_CFG"
  sed -i '/^variable_fan1_min:/d' "$MACRO_CFG"

  cat <<'EOF' >> "$MACRO_CFG"

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

[gcode_macro M106]
description: Set Fan Speed. P0 for part
gcode:
  {% set fan_id = params.P|default(0)|int %}
  {% if fan_id == 0 %}
    {% set speed_param = params.S|default(255)|int %}
    {% if speed_param > 0 %}
      {% set speed = (speed_param|float / 255) %}
    {% else %}
      {% set speed = 0 %}
    {% endif %}
    SET_FAN_SPEED FAN=part SPEED={speed}
  {% endif %}

[gcode_macro M107]
description: Set Fan Off. P0 for part
gcode:
  SET_FAN_SPEED FAN=part SPEED=0

[gcode_macro TURN_OFF_FANS]
description: Stop chamber, auxiliary and part fan
gcode:
    SET_FAN_SPEED FAN=part SPEED=0

[gcode_macro TURN_ON_FANS]
description: Turn on chamber, auxiliary and part fan
gcode:
    SET_FAN_SPEED FAN=part SPEED=1
EOF

  echo -e "${GREEN}✅ Новые настройки применены.${RESET}"
  echo -e "${YELLOW}🔄 Перезапуск Klipper...${RESET}"
  curl -s -X POST "http://localhost:7125/printer/restart"
}

restore_backup() {
  if [[ -f "$PRINTER_BAK" && -f "$MACRO_BAK" ]]; then
    cp -p "$PRINTER_BAK" "$PRINTER_CFG"
    cp -p "$MACRO_BAK" "$MACRO_CFG"
    echo -e "${YELLOW}♻️  Конфиги восстановлены из бэкапов.${RESET}"
    echo -e "${YELLOW}🔄 Перезапуск Klipper...${RESET}"
    curl -s -X POST "http://localhost:7125/printer/restart"
    echo -e "${GREEN}✅ Восстановление завершено.${RESET}"
  else
    echo -e "${YELLOW}❗ Бэкапы не найдены.${RESET}"
  fi
}

# --- Меню ---
show_header
echo -e "${GREEN}1) Применить новые настройки${RESET}"
echo -e "${GREEN}2) Откатиться на бэкапы${RESET}"
echo -e "${GREEN}q) Выйти${RESET}"
echo -n "Выберите действие: "
read choice

case "$choice" in
  1) apply_fixes ;;
  2) restore_backup ;;
  q|Q) echo -e "${YELLOW}🚪 Выход.${RESET}" ;;
  *) echo -e "${YELLOW}❓ Неверный выбор${RESET}" ;;
esac
