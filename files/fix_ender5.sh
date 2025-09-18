#!/bin/bash
set -u

# ================================
#   Tom Tomich Script v2.9
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
  echo -e "${YELLOW}========================================${RESET}"
  echo -e "${YELLOW}🚀 Tom Tomich Script v2.9 (Nebula Pad)${RESET}"
  echo -e "${YELLOW} Helper & Fix Tool for Ender-5 Max${RESET}"
  echo -e "${YELLOW}========================================${RESET}"
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

prepare_helper() {
  if [ ! -d "$HELPER_DIR" ]; then
    echo -e "${YELLOW}📥 Скачиваем Helper Script...${RESET}"
    git clone https://github.com/Guilouz/Creality-Helper-Script.git "$HELPER_DIR"
    if [ $? -ne 0 ]; then
      echo -e "${RED}❌ Ошибка загрузки Helper Script${RESET}"
      exit 1
    fi
  else
    echo -e "${YELLOW}🔄 Обновляем Helper Script...${RESET}"
    cd "$HELPER_DIR" && git pull
  fi
}

# Проверки установки (по папкам/файлам)
is_installed_moonraker() { [ -d "/usr/share/moonraker" ]; }
is_installed_fluidd() { [ -d "/usr/share/fluidd" ]; }
is_installed_mainsail() { [ -d "/usr/share/mainsail" ]; }
is_installed_entware() { [ -d "/opt/bin" ]; }
is_installed_shell() { grep -q "gcode_shell_command" "$PRINTER_CFG" 2>/dev/null; }
is_installed_shapers() { [ -d "/usr/data/shaper_calibrations" ]; }

# Helper Script вызовы
install_moonraker() { sh "$HELPER_DIR/scripts/e5m/install-moonraker.sh"; }
remove_moonraker() { sh "$HELPER_DIR/scripts/e5m/remove-moonraker.sh"; }

install_fluidd() { sh "$HELPER_DIR/scripts/e5m/install-fluidd.sh"; }
remove_fluidd() { sh "$HELPER_DIR/scripts/e5m/remove-fluidd.sh"; }

install_mainsail() { sh "$HELPER_DIR/scripts/e5m/install-mainsail.sh"; }
remove_mainsail() { sh "$HELPER_DIR/scripts/e5m/remove-mainsail.sh"; }

install_entware() { sh "$HELPER_DIR/scripts/e5m/install-entware.sh"; }
remove_entware() { sh "$HELPER_DIR/scripts/e5m/remove-entware.sh"; }

enable_gcode_shell_command() { sh "$HELPER_DIR/scripts/e5m/enable-gcode-shell-command.sh"; }
disable_gcode_shell_command() { sh "$HELPER_DIR/scripts/e5m/disable-gcode-shell-command.sh"; }

install_shaper_calibrations() { sh "$HELPER_DIR/scripts/e5m/install-shaper-calibrations.sh"; }
remove_shaper_calibrations() { sh "$HELPER_DIR/scripts/e5m/remove-shaper-calibrations.sh"; }

# ---------- Исправления Ender-5 Max ----------
fix_e5m() {
  cp -p "$PRINTER_CFG" "$PRINTER_BAK"
  cp -p "$MACRO_CFG" "$MACRO_BAK"
  echo -e "${YELLOW}📂 Созданы бэкапы.${RESET}"

  # printer.cfg правки
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

[gcode_shell_command beep]
command: beep
timeout: 2
verbose: False
EOF

  # gcode_macro.cfg правки
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

[gcode_macro BEEP]
description: Play a sound
gcode:
  RUN_SHELL_COMMAND CMD=beep
EOF

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
prepare_helper
show_header

echo -e "${YELLOW}[УСТАНОВКА]${RESET}"
echo "[1]  Установить Moonraker"
echo "[2]  Установить Fluidd"
echo "[3]  Установить Mainsail"
echo "[4]  Установить Entware"
echo "[5]  Включить Klipper Gcode Shell Command"
echo "[6]  Установить Improved Shapers Calibrations"
echo "[8]  Исправления конфигов для Ender-5 Max"
echo ""

echo -e "${YELLOW}[УДАЛЕНИЕ]${RESET}"
if is_installed_moonraker; then echo "[1r] Удалить Moonraker       ${GREEN}🟢${RESET}"; else echo "[1r] Удалить Moonraker       ${RED}🔴${RESET}"; fi
if is_installed_fluidd; then echo "[2r] Удалить Fluidd          ${GREEN}🟢${RESET}"; else echo "[2r] Удалить Fluidd          ${RED}🔴${RESET}"; fi
if is_installed_mainsail; then echo "[3r] Удалить Mainsail        ${GREEN}🟢${RESET}"; else echo "[3r] Удалить Mainsail        ${RED}🔴${RESET}"; fi
if is_installed_entware; then echo "[4r] Удалить Entware         ${GREEN}🟢${RESET}"; else echo "[4r] Удалить Entware         ${RED}🔴${RESET}"; fi
if is_installed_shell; then echo "[5r] Выключить Gcode Shell   ${GREEN}🟢${RESET}"; else echo "[5r] Выключить Gcode Shell   ${RED}🔴${RESET}"; fi
if is_installed_shapers; then echo "[6r] Удалить Shapers         ${GREEN}🟢${RESET}"; else echo "[6r] Удалить Shapers         ${RED}🔴${RESET}"; fi
echo "[9]  Откатить исправления Ender-5 Max"
echo ""
echo "[q]  Выйти"
echo -e "${YELLOW}----------------------------------------${RESET}"
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
