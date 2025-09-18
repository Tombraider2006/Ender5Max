#!/bin/bash
set -u

# ================================
#   Tom Tomich Script v3.4
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
  printf "%b\n" "${YELLOW}🚀 Tom Tomich Script v3.4 (Nebula Pad)${RESET}"
  printf "%b\n" "${YELLOW} Helper & Fix Tool for Ender-5 Max${RESET}"
  printf "%b\n" "${YELLOW}========================================${RESET}"
  echo ""
}

confirm_action() {
  printf "Вы уверены? (y/n): "
  read -r ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
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
}

restart_klipper() {
  printf "%b\n" "${YELLOW}🔄 Попытка перезапуска Klipper...${RESET}"
  if command -v curl >/dev/null 2>&1; then
    curl -s -X POST "http://localhost:7125/printer/restart"       && { printf "%b\n" "${GREEN}✅ Klipper перезапущен (Moonraker API)${RESET}"; return; }
  fi
  printf "%b\n" "${YELLOW}⚠️ Не удалось автоматически перезапустить Klipper. Выполните перезапуск вручную.${RESET}"
}

# Проверки установки
is_installed_moonraker() { [ -d "/usr/share/moonraker" ]; }
is_installed_fluidd() { [ -d "/usr/share/fluidd" ]; }
is_installed_mainsail() { [ -d "/usr/share/mainsail" ]; }
is_installed_entware() { [ -d "/opt/bin" ]; }
is_installed_shell() { grep -q "gcode_shell_command" "$PRINTER_CFG" 2>/dev/null; }
is_installed_shapers() { [ -d "/usr/data/shaper_calibrations" ]; }
is_installed_e5mfix() { [[ -f "$PRINTER_BAK" && -f "$MACRO_BAK" ]]; }

# Вызовы install/remove скриптов Guilouz
install_moonraker() { sh "$HELPER_DIR/scripts/moonraker_nginx.sh"; }
remove_moonraker() { sh "$HELPER_DIR/scripts/moonraker_nginx.sh" remove; }

install_fluidd() { sh "$HELPER_DIR/scripts/fluidd.sh"; }
remove_fluidd() { sh "$HELPER_DIR/scripts/fluidd.sh" remove; }

install_mainsail() { sh "$HELPER_DIR/scripts/mainsail.sh"; }
remove_mainsail() { sh "$HELPER_DIR/scripts/mainsail.sh" remove; }

install_entware() { sh "$HELPER_DIR/scripts/entware.sh"; }
remove_entware() { sh "$HELPER_DIR/scripts/entware.sh" remove; }

install_shell() { sh "$HELPER_DIR/scripts/gcode_shell_command.sh"; }
remove_shell() { sh "$HELPER_DIR/scripts/gcode_shell_command.sh" remove; }

install_shapers() { sh "$HELPER_DIR/scripts/improved_shapers.sh"; }
remove_shapers() { sh "$HELPER_DIR/scripts/improved_shapers.sh" remove; }

# ---------- Исправления Ender-5 Max ----------
fix_e5m() {
  echo "⚙️ Применяются исправления Ender-5 Max..."
  cp -p "$PRINTER_CFG" "$PRINTER_BAK"
  cp -p "$MACRO_CFG" "$MACRO_BAK"
  echo "📂 Созданы бэкапы."

  echo "🧹 Чистим старые секции..."
  sed -i 's/^\[output_pin Height_module2\]/[output_pin _Height_module2]/' "$PRINTER_CFG"
  for pat in "output_pin light_pin" "output_pin MainBoardFan" "output_pin fan0" "output_pin en_fan0" \
             "output_pin fan1" "output_pin en_fan1" "multi_pin part_fans" "multi_pin en_part_fans" \
             "fan_generic part" "controller_fan MCU_fan"; do
    sed -i "/^\[$pat\]/,/^$/d" "$PRINTER_CFG"
    sed -i "/^\[$pat\]/,/^\[/d" "$PRINTER_CFG"
  done

  echo "➕ Добавляем новые секции в printer.cfg..."
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

  echo "🧹 Чистим старые секции в gcode_macro.cfg..."
  for pat in "gcode_macro M106" "gcode_macro M107" "gcode_macro TURN_OFF_FANS" "gcode_macro TURN_ON_FANS" \
             "firmware_retraction" "gcode_shell_command beep" "gcode_macro BEEP" \
             "delayed_gcode light_init" "exclude_object" "gcode_macro PID_BED" "gcode_macro PID_HOTEND"; do
    sed -i "/^\[$pat\]/,/^$/d" "$MACRO_CFG"
    sed -i "/^\[$pat\]/,/^\[/d" "$MACRO_CFG"
  done
  sed -i '/^variable_fan0_min:/d' "$MACRO_CFG"
  sed -i '/^variable_fan1_min:/d' "$MACRO_CFG"

  echo "➕ Добавляем новые секции в gcode_macro.cfg..."
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

  echo "✅ Исправления для Ender-5 Max применены."
  restart_klipper
}

restore_e5m() {
  echo "♻️ Восстанавливаются бэкапы Ender-5 Max..."
  if [[ -f "$PRINTER_BAK" && -f "$MACRO_BAK" ]]; then
    cp -p "$PRINTER_BAK" "$PRINTER_CFG"
    cp -p "$MACRO_BAK" "$MACRO_CFG"
    echo "📂 Конфиги восстановлены."
    restart_klipper
    echo "✅ Восстановление завершено."
  else
    echo "❗ Бэкапы не найдены."
  fi
}

# ----- Меню установки -----
menu_install() {
  while true; do
    show_header
    printf "%b\n" "${YELLOW}[УСТАНОВКА]${RESET}"
    if is_installed_moonraker; then printf "[1] %b\n" "${GREEN}🟢 Установить Moonraker${RESET}"; else printf "[1] %b\n" "${RED}🔴 Установить Moonraker${RESET}"; fi
    if is_installed_fluidd; then printf "[2] %b\n" "${GREEN}🟢 Установить Fluidd${RESET}"; else printf "[2] %b\n" "${RED}🔴 Установить Fluidd${RESET}"; fi
    if is_installed_mainsail; then printf "[3] %b\n" "${GREEN}🟢 Установить Mainsail${RESET}"; else printf "[3] %b\n" "${RED}🔴 Установить Mainsail${RESET}"; fi
    if is_installed_entware; then printf "[4] %b\n" "${GREEN}🟢 Установить Entware${RESET}"; else printf "[4] %b\n" "${RED}🔴 Установить Entware${RESET}"; fi
    if is_installed_shell; then printf "[5] %b\n" "${GREEN}🟢 Включить Klipper Gcode Shell Command${RESET}"; else printf "[5] %b\n" "${RED}🔴 Включить Klipper Gcode Shell Command${RESET}"; fi
    if is_installed_shapers; then printf "[6] %b\n" "${GREEN}🟢 Установить Improved Shapers Calibrations${RESET}"; else printf "[6] %b\n" "${RED}🔴 Установить Improved Shapers Calibrations${RESET}"; fi
    if is_installed_e5mfix; then printf "[8] %b\n" "${GREEN}🟢 Исправления конфигов для Ender-5 Max${RESET}"; else printf "[8] %b\n" "${RED}🔴 Исправления конфигов для Ender-5 Max${RESET}"; fi
    echo "[b] Назад в главное меню"
    echo ""
    printf "Выберите действие: "
    read -r choice
    case "$choice" in
      1) if confirm_action; then echo "⚙️ Устанавливается Moonraker..."; install_moonraker; echo "✅ Установка Moonraker завершена."; read -p "Нажмите Enter..."; fi;;
      2) if confirm_action; then echo "⚙️ Устанавливается Fluidd..."; install_fluidd; echo "✅ Установка Fluidd завершена."; read -p "Нажмите Enter..."; fi;;
      3) if confirm_action; then echo "⚙️ Устанавливается Mainsail..."; install_mainsail; echo "✅ Установка Mainsail завершена."; read -p "Нажмите Enter..."; fi;;
      4) if confirm_action; then echo "⚙️ Устанавливается Entware..."; install_entware; echo "✅ Установка Entware завершена."; read -p "Нажмите Enter..."; fi;;
      5) if confirm_action; then echo "⚙️ Включается Gcode Shell..."; install_shell; echo "✅ Gcode Shell включен."; read -p "Нажмите Enter..."; fi;;
      6) if confirm_action; then echo "⚙️ Устанавливается Shapers..."; install_shapers; echo "✅ Установка Shapers завершена."; read -p "Нажмите Enter..."; fi;;
      8) if confirm_action; then fix_e5m; read -p "Нажмите Enter..."; fi;;
      b|B) return ;;
    esac
  done
}

# ----- Меню удаления -----
menu_remove() {
  while true; do
    show_header
    printf "%b\n" "${YELLOW}[УДАЛЕНИЕ]${RESET}"
    if is_installed_moonraker; then printf "[1] %b\n" "${GREEN}🟢 Удалить Moonraker${RESET}"; else printf "[1] %b\n" "${RED}🔴 Удалить Moonraker${RESET}"; fi
    if is_installed_fluidd; then printf "[2] %b\n" "${GREEN}🟢 Удалить Fluidd${RESET}"; else printf "[2] %b\n" "${RED}🔴 Удалить Fluidd${RESET}"; fi
    if is_installed_mainsail; then printf "[3] %b\n" "${GREEN}🟢 Удалить Mainsail${RESET}"; else printf "[3] %b\n" "${RED}🔴 Удалить Mainsail${RESET}"; fi
    if is_installed_entware; then printf "[4] %b\n" "${GREEN}🟢 Удалить Entware${RESET}"; else printf "[4] %b\n" "${RED}🔴 Удалить Entware${RESET}"; fi
    if is_installed_shell; then printf "[5] %b\n" "${GREEN}🟢 Выключить Klipper Gcode Shell Command${RESET}"; else printf "[5] %b\n" "${RED}🔴 Выключить Klipper Gcode Shell Command${RESET}"; fi
    if is_installed_shapers; then printf "[6] %b\n" "${GREEN}🟢 Удалить Improved Shapers Calibrations${RESET}"; else printf "[6] %b\n" "${RED}🔴 Удалить Improved Shapers Calibrations${RESET}"; fi
    if is_installed_e5mfix; then printf "[9] %b\n" "${GREEN}🟢 Откатить исправления Ender-5 Max${RESET}"; else printf "[9] %b\n" "${RED}🔴 Откатить исправления Ender-5 Max${RESET}"; fi
    echo "[b] Назад в главное меню"
    echo ""
    printf "Выберите действие: "
    read -r choice
    case "$choice" in
      1) if confirm_action; then echo "⚙️ Удаляется Moonraker..."; remove_moonraker; echo "✅ Удаление Moonraker завершено."; read -p "Нажмите Enter..."; fi;;
      2) if confirm_action; then echo "⚙️ Удаляется Fluidd..."; remove_fluidd; echo "✅ Удаление Fluidd завершено."; read -p "Нажмите Enter..."; fi;;
      3) if confirm_action; then echo "⚙️ Удаляется Mainsail..."; remove_mainsail; echo "✅ Удаление Mainsail завершено."; read -p "Нажмите Enter..."; fi;;
      4) if confirm_action; then echo "⚙️ Удаляется Entware..."; remove_entware; echo "✅ Удаление Entware завершено."; read -p "Нажмите Enter..."; fi;;
      5) if confirm_action; then echo "⚙️ Выключается Gcode Shell..."; remove_shell; echo "✅ Gcode Shell выключен."; read -p "Нажмите Enter..."; fi;;
      6) if confirm_action; then echo "⚙️ Удаляются Shapers..."; remove_shapers; echo "✅ Удаление Shapers завершено."; read -p "Нажмите Enter..."; fi;;
      9) if confirm_action; then restore_e5m; read -p "Нажмите Enter..."; fi;;
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
  read -r choice
  case "$choice" in
    1) menu_install ;;
    2) menu_remove ;;
    q|Q) echo "Выход..." ; exit 0 ;;
  esac
done
