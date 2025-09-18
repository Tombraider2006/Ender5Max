#!/bin/bash
set -u

# ================================
#   Tom Tomich Script v2.4
#   Helper & Fix Tool for Ender-5 Max
# ================================

BLUE="\033[1;34m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"
PRINTER_BAK="${PRINTER_CFG}.bak"
MACRO_BAK="${MACRO_CFG}.bak"

show_header() {
  clear
  echo -e "${BLUE}#############################################${RESET}"
  echo -e "${BLUE}#                                           #${RESET}"
  echo -e "${BLUE}#         🚀 Tom Tomich Script v2.4         #${RESET}"
  echo -e "${BLUE}#   Helper & Fix Tool for Ender-5 Max       #${RESET}"
  echo -e "${BLUE}#                                           #${RESET}"
  echo -e "${BLUE}#############################################${RESET}"
  echo ""
}

restart_klipper() {
  echo -e "${YELLOW}🔄 Попытка перезапуска Klipper...${RESET}"
  if [[ -x "/etc/init.d/klipper" ]]; then
    /etc/init.d/klipper restart && { echo -e "${GREEN}✅ Klipper перезапущен (/etc/init.d)${RESET}"; return; }
  fi
  if command -v service >/dev/null 2>&1; then
    service klipper restart && { echo -e "${GREEN}✅ Klipper перезапущен (service)${RESET}"; return; }
  fi
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart klipper && { echo -e "${GREEN}✅ Klipper перезапущен (systemctl)${RESET}"; return; }
  fi
  if command -v curl >/dev/null 2>&1; then
    curl -s -X POST "http://localhost:7125/printer/restart" && { echo -e "${GREEN}✅ Klipper перезапущен (Moonraker API)${RESET}"; return; }
  fi
  echo -e "${YELLOW}⚠️ Не удалось автоматически перезапустить Klipper. Выполните перезапуск вручную.${RESET}"
}

# ---------- Helper Script интеграции ----------

install_moonraker() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/01-install-moonraker.sh" | sh; }
remove_moonraker() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/01-remove-moonraker.sh" | sh; }

install_fluidd() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/02-install-fluidd.sh" | sh; }
remove_fluidd() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/02-remove-fluidd.sh" | sh; }

install_mainsail() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/03-install-mainsail.sh" | sh; }
remove_mainsail() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/03-remove-mainsail.sh" | sh; }

install_entware() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/04-install-entware.sh" | sh; }
remove_entware() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/04-remove-entware.sh" | sh; }

enable_gcode_shell_command() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/05-enable-gcode-shell-command.sh" | sh; }
disable_gcode_shell_command() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/05-disable-gcode-shell-command.sh" | sh; }

install_shaper_calibrations() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/06-install-shaper-calibrations.sh" | sh; }
remove_shaper_calibrations() { wget -q --no-check-certificate -O - "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/06-remove-shaper-calibrations.sh" | sh; }

# ---------- Исправления Ender-5 Max ----------

fix_e5m() {
  cp -p "$PRINTER_CFG" "$PRINTER_BAK"
  cp -p "$MACRO_CFG" "$MACRO_BAK"
  echo -e "${YELLOW}📂 Созданы бэкапы.${RESET}"

  # --- printer.cfg ---
  sed -i 's/^\[output_pin Height_module2\]/[output_pin _Height_module2]/' "$PRINTER_CFG"
  for pat in "output_pin light_pin" "output_pin MainBoardFan" "output_pin fan0" "output_pin en_fan0" \
             "output_pin fan1" "output_pin en_fan1" "multi_pin part_fans" "multi_pin en_part_fans" \
             "fan_generic part" "controller_fan MCU_fan"; do
    sed -i "/^\[$pat\]/,/^$/d" "$PRINTER_CFG"
    sed -i "/^\[$pat\]/,/^\[/d" "$PRINTER_CFG"
  done
  cat <<'EOF' >> "$PRINTER_CFG"

[output_pin light_pin]
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0

[controller_fan MCU_fan]
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
             "delayed_gcode light_init" "exclude_object" "gcode_macro PID_BED" "gcode_macro PID_HOTEND"; do
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
gcode:
  {% set fan_id = params.P|default(0)|int %}
  {% if fan_id == 0 %}
    {% set speed_param = params.S|default(255)|int %}
    {% set speed = (speed_param|float / 255) if speed_param > 0 else 0 %}
    SET_FAN_SPEED FAN=part SPEED={speed}
  {% endif %}

[gcode_macro M107]
gcode:
  SET_FAN_SPEED FAN=part SPEED=0

[gcode_macro TURN_OFF_FANS]
gcode:
  SET_FAN_SPEED FAN=part SPEED=0

[gcode_macro TURN_ON_FANS]
gcode:
  SET_FAN_SPEED FAN=part SPEED=1
EOF

  # добавляем beep в printer.cfg
  if ! grep -qF "[gcode_shell_command beep]" "$PRINTER_CFG"; then
    cat <<'EOF' >> "$PRINTER_CFG"

[gcode_shell_command beep]
command: beep
timeout: 2
verbose: False
EOF
  fi

  # добавляем макрос BEEP
  if ! grep -qF "[gcode_macro BEEP]" "$MACRO_CFG"; then
    cat <<'EOF' >> "$MACRO_CFG"

[gcode_macro BEEP]
description: Play a sound
gcode:
  RUN_SHELL_COMMAND CMD=beep
EOF
  fi

  echo -e "${GREEN}✅ Исправления для Ender-5 Max применены.${RESET}"
  restart_klipper
}

restore_e5m() {
  if [[ -f "$PRINTER_BAK" && -f "$MACRO_BAK" ]]; then
    cp -p "$PRINTER_BAK" "$PRINTER_CFG"
    cp -p "$MACRO_BAK" "$MACRO_CFG"
    echo -e "${YELLOW}♻️ Конфиги Ender-5 Max восстановлены.${RESET}"
    restart_klipper
    echo -e "${GREEN}✅ Восстановление завершено.${RESET}"
  else
    echo -e "${YELLOW}❗ Бэкапы не найдены.${RESET}"
  fi
}

# ---------- Меню ----------

show_header
echo -e "${GREEN}1) Установить Moonraker${RESET}"
echo -e "${GREEN}1r) Удалить Moonraker${RESET}"
echo -e "${GREEN}2) Установить Fluidd${RESET}"
echo -e "${GREEN}2r) Удалить Fluidd${RESET}"
echo -e "${GREEN}3) Установить Mainsail${RESET}"
echo -e "${GREEN}3r) Удалить Mainsail${RESET}"
echo -e "${GREEN}4) Установить Entware${RESET}"
echo -e "${GREEN}4r) Удалить Entware${RESET}"
echo -e "${GREEN}5) Включить Klipper Gcode Shell Command${RESET}"
echo -e "${GREEN}5r) Выключить Klipper Gcode Shell Command${RESET}"
echo -e "${GREEN}6) Установить Improved Shapers Calibrations${RESET}"
echo -e "${GREEN}6r) Удалить Improved Shapers Calibrations${RESET}"
echo -e "${GREEN}8) Исправления конфигов для Ender-5 Max${RESET}"
echo -e "${GREEN}9) Откатить исправления Ender-5 Max${RESET}"
echo -e "${GREEN}q) Выйти${RESET}"
echo -n "Выберите действие: "
read -r choice

case "$choice" in
  1) install_moonraker ;;
  1r) remove_moonraker ;;
  2) install_fluidd ;;
  2r) remove_fluidd ;;
  3) install_mainsail ;;
  3r) remove_mainsail ;;
  4) install_entware ;;
  4r) remove_entware ;;
  5) enable_gcode_shell_command ;;
  5r) disable_gcode_shell_command ;;
  6) install_shaper_calibrations ;;
  6r) remove_shaper_calibrations ;;
  8) fix_e5m ;;
  9) restore_e5m ;;
  q|Q) echo -e "${YELLOW}🚪 Выход.${RESET}" ;;
  *) echo -e "${YELLOW}❓ Неверный выбор${RESET}" ;;
esac
