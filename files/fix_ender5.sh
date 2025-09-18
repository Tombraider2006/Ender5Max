#!/bin/bash
set -u

# ================================
#   Tom Tomich Script v2.1
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
  echo -e "${BLUE}#         🚀 Tom Tomich Script v2.1         #${RESET}"
  echo -e "${BLUE}#   Helper & Fix Tool for Ender-5 Max       #${RESET}"
  echo -e "${BLUE}#                                           #${RESET}"
  echo -e "${BLUE}#############################################${RESET}"
  echo ""
}

# Универсальная функция перезапуска Klipper (как в helper-script: init.d / service / systemctl / Moonraker)
restart_klipper() {
  echo -e "${YELLOW}🔄 Попытка перезапуска Klipper...${RESET}"
  # 1) init.d
  if [[ -x "/etc/init.d/klipper" ]]; then
    /etc/init.d/klipper restart && { echo -e "${GREEN}✅ Klipper перезапущен через /etc/init.d/klipper${RESET}"; return 0; }
  fi

  # 2) service
  if command -v service >/dev/null 2>&1; then
    service klipper restart && { echo -e "${GREEN}✅ Klipper перезапущен через service${RESET}"; return 0; }
  fi

  # 3) systemctl (если доступен)
  if command -v systemctl >/dev/null 2>&1; then
    if sudo systemctl restart klipper >/dev/null 2>&1; then
      echo -e "${GREEN}✅ Klipper перезапущен через systemctl${RESET}"
      return 0
    fi
  fi

  # 4) Moonraker API (fallback)
  if command -v curl >/dev/null 2>&1; then
    curl -s -X POST "http://localhost:7125/printer/restart" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
      echo -e "${GREEN}✅ Klipper перезапущен через Moonraker API${RESET}"
      return 0
    fi
  fi

  echo -e "${YELLOW}⚠️ Не удалось автоматически перезапустить Klipper. Выполните перезапуск вручную.${RESET}"
  return 1
}

# ---------- Установки / дополнительные функции ----------

install_moonraker() {
  echo -e "${YELLOW}📥 Устанавливаем Moonraker...${RESET}"
  cd /usr/share || { echo -e "${YELLOW}❗ Не могу перейти в /usr/share${RESET}"; return 1; }
  if [[ -d "moonraker" ]]; then
    echo -e "${YELLOW}▶ moonraker уже существует, обновляю...${RESET}"
    cd moonraker && git pull || true
  else
    git clone https://github.com/Arksine/moonraker moonraker || { echo -e "${YELLOW}❗ git clone failed${RESET}"; return 1; }
  fi
  cd moonraker || return 1
  if [[ -x "./scripts/install-moonraker.sh" ]]; then
    ./scripts/install-moonraker.sh || echo -e "${YELLOW}⚠️ Скрипт установки вернул ошибку${RESET}"
  else
    echo -e "${YELLOW}⚠️ install script not found, проверьте репозиторий${RESET}"
  fi
  echo -e "${GREEN}✅ Moonraker установлен/обновлён.${RESET}"
  restart_klipper
}

install_fluidd() {
  echo -e "${YELLOW}📥 Устанавливаем Fluidd...${RESET}"
  mkdir -p /usr/share/nginx/html/fluidd
  TMPZIP="/tmp/fluidd.zip"
  wget -q --no-check-certificate "https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip" -O "$TMPZIP" || { echo -e "${YELLOW}❗ Скачивание fluidd.zip не удалось${RESET}"; return 1; }
  unzip -o "$TMPZIP" -d /usr/share/nginx/html/fluidd >/dev/null 2>&1 || true
  rm -f "$TMPZIP"
  echo -e "${GREEN}✅ Fluidd установлен.${RESET}"
}

install_mainsail() {
  echo -e "${YELLOW}📥 Устанавливаем Mainsail...${RESET}"
  mkdir -p /usr/share/nginx/html/mainsail
  TMPZIP="/tmp/mainsail.zip"
  wget -q --no-check-certificate "https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip" -O "$TMPZIP" || { echo -e "${YELLOW}❗ Скачивание mainsail.zip не удалось${RESET}"; return 1; }
  unzip -o "$TMPZIP" -d /usr/share/nginx/html/mainsail >/dev/null 2>&1 || true
  rm -f "$TMPZIP"
  echo -e "${GREEN}✅ Mainsail установлен.${RESET}"
}

install_entware() {
  echo -e "${YELLOW}📥 Устанавливаем Entware...${RESET}"
  wget -q --no-check-certificate -O - http://bin.entware.net/armv7sf-k3.2/installer/generic.sh | sh || { echo -e "${YELLOW}❗ Установка Entware вернула ошибку${RESET}"; return 1; }
  # добавить PATH в профиль
  if ! grep -q "/opt/bin" /etc/profile 2>/dev/null; then
    echo 'export PATH=$PATH:/opt/bin:/opt/sbin' >> /etc/profile || true
  fi
  echo -e "${GREEN}✅ Entware установлен.${RESET}"
}

enable_gcode_shell_command() {
  echo -e "${YELLOW}⚙️ Включаем Klipper Gcode Shell Command...${RESET}"

  # Добавляем [gcode_shell_command beep] в printer.cfg (если нет)
  if ! grep -qF "[gcode_shell_command beep]" "$PRINTER_CFG"; then
    cat <<'EOF' >> "$PRINTER_CFG"

[gcode_shell_command beep]
command: beep
timeout: 2
verbose: False
EOF
    echo -e "${YELLOW}➕ Добавлено [gcode_shell_command beep] в $PRINTER_CFG${RESET}"
  else
    echo -e "${YELLOW}ℹ️ [gcode_shell_command beep] уже присутствует в $PRINTER_CFG${RESET}"
  fi

  # Добавляем макрос BEEP в gcode_macro.cfg (если нет)
  if ! grep -qF "[gcode_macro BEEP]" "$MACRO_CFG"; then
    cat <<'EOF' >> "$MACRO_CFG"

[gcode_macro BEEP] # звук бип.
description: Play a sound
gcode:
  RUN_SHELL_COMMAND CMD=beep
EOF
    echo -e "${YELLOW}➕ Добавлен макрос BEEP в $MACRO_CFG${RESET}"
  else
    echo -e "${YELLOW}ℹ️ Макрос BEEP уже присутствует в $MACRO_CFG${RESET}"
  fi

  restart_klipper
  echo -e "${GREEN}✅ Gcode Shell Command включен.${RESET}"
}

install_shaper_calibrations() {
  echo -e "${YELLOW}📥 Устанавливаем Improved Shaper Calibrations...${RESET}"
  cd /usr/share || { echo -e "${YELLOW}❗ Не могу перейти в /usr/share${RESET}"; return 1; }
  if [[ -d "shaper-calibrations" ]]; then
    cd shaper-calibrations && git pull || true
  else
    git clone https://github.com/Guilouz/klipper-shaper-calibrations shaper-calibrations || { echo -e "${YELLOW}❗ git clone failed${RESET}"; return 1; }
  fi
  echo -e "${GREEN}✅ Improved Shaper Calibrations установлены.${RESET}"
}

# ---------- Fixes for Ender-5 Max ----------
fix_e5m() {
  # проверка файлов
  if [[ ! -f "$PRINTER_CFG" || ! -f "$MACRO_CFG" ]]; then
    echo -e "${YELLOW}❗ Один из конфигов не найден. Проверьте: ${PRINTER_CFG}, ${MACRO_CFG}${RESET}"
    return 1
  fi

  cp -p "$PRINTER_CFG" "$PRINTER_BAK"
  cp -p "$MACRO_CFG" "$MACRO_BAK"
  echo -e "${YELLOW}📂 Созданы бэкапы:${RESET}"
  echo -e "   $PRINTER_BAK"
  echo -e "   $MACRO_BAK"

  # 1) Height_module2 -> _Height_module2
  sed -i 's/^\[output_pin Height_module2\]/[output_pin _Height_module2]/' "$PRINTER_CFG"

  # 2) Удаляем старые light_pin / MainBoardFan / fan0..fan1 / multi_pin / controller_fan
  for pat in "output_pin light_pin" "output_pin MainBoardFan" \
             "output_pin fan0" "output_pin en_fan0" "output_pin fan1" "output_pin en_fan1" \
             "multi_pin part_fans" "multi_pin en_part_fans" "fan_generic part" "controller_fan MCU_fan"
  do
    sed -i "/^\[$pat\]/,/^$/d" "$PRINTER_CFG"
    sed -i "/^\[$pat\]/,/^\[/d" "$PRINTER_CFG"
  done

  # 3) Добавляем новые блоки в printer.cfg
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

  # 4) gcode_macro.cfg — удаляем старые макросы и переменные
  for pat in "gcode_macro M106" "gcode_macro M107" "gcode_macro TURN_OFF_FANS" "gcode_macro TURN_ON_FANS" \
             "firmware_retraction" "gcode_shell_command beep" "gcode_macro BEEP" \
             "delayed_gcode light_init" "exclude_object" "gcode_macro PID_BED" "gcode_macro PID_HOTEND"
  do
    sed -i "/^\[$pat\]/,/^$/d" "$MACRO_CFG"
    sed -i "/^\[$pat\]/,/^\[/d" "$MACRO_CFG"
  done
  sed -i '/^variable_fan0_min:/d' "$MACRO_CFG"
  sed -i '/^variable_fan1_min:/d' "$MACRO_CFG"

  # 5) Добавляем необходимые блоки в gcode_macro.cfg (без дублирования beep в неправильном месте)
  cat <<'EOF' >> "$MACRO_CFG"

[firmware_retraction]
retract_length: 0.45 # безопасное значение
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

  # 6) Убедимся, что [gcode_shell_command beep] находится в printer.cfg (как в helper-script)
  if ! grep -qF "[gcode_shell_command beep]" "$PRINTER_CFG"; then
    cat <<'EOF' >> "$PRINTER_CFG"

[gcode_shell_command beep]
command: beep
timeout: 2
verbose: False
EOF
    echo -e "${YELLOW}➕ Добавлено [gcode_shell_command beep] в $PRINTER_CFG${RESET}"
  fi

  # 7) И макрос BEEP в gcode_macro.cfg (если нет) — ставим корректный макрос
  if ! grep -qF "[gcode_macro BEEP]" "$MACRO_CFG"; then
    cat <<'EOF' >> "$MACRO_CFG"

[gcode_macro BEEP] # звук бип.
description: Play a sound
gcode:
  RUN_SHELL_COMMAND CMD=beep
EOF
    echo -e "${YELLOW}➕ Добавлен макрос BEEP в $MACRO_CFG${RESET}"
  fi

  echo -e "${GREEN}✅ Исправления для Ender-5 Max применены.${RESET}"
  restart_klipper
}

restore_e5m() {
  if [[ -f "$PRINTER_BAK" && -f "$MACRO_BAK" ]]; then
    cp -p "$PRINTER_BAK" "$PRINTER_CFG"
    cp -p "$MACRO_BAK" "$MACRO_CFG"
    echo -e "${YELLOW}♻️  Конфиги Ender-5 Max восстановлены.${RESET}"
    restart_klipper
    echo -e "${GREEN}✅ Восстановление завершено.${RESET}"
  else
    echo -e "${YELLOW}❗ Бэкапы не найдены.${RESET}"
  fi
}

# ---------- Меню ----------
show_header
echo -e "${GREEN}1) Установить Moonraker${RESET}"
echo -e "${GREEN}2) Установить Fluidd${RESET}"
echo -e "${GREEN}3) Установить Mainsail${RESET}"
echo -e "${GREEN}4) Установить Entware${RESET}"
echo -e "${GREEN}5) Включить Klipper Gcode Shell Command${RESET}"
echo -e "${GREEN}6) Установить Improved Shapers Calibrations${RESET}"
echo -e "${GREEN}7) (резерв)${RESET}"
echo -e "${GREEN}8) Исправления конфигов для Ender-5 Max${RESET}"
echo -e "${GREEN}9) Откатить исправления Ender-5 Max${RESET}"
echo -e "${GREEN}q) Выйти${RESET}"
echo -n "Выберите действие: "
read -r choice

case "$choice" in
  1) install_moonraker ;;
  2) install_fluidd ;;
  3) install_mainsail ;;
  4) install_entware ;;
  5) enable_gcode_shell_command ;;
  6) install_shaper_calibrations ;;
  7) echo -e "${YELLOW}Резервный пункт.${RESET}" ;;
  8) fix_e5m ;;
  9) restore_e5m ;;
  q|Q) echo -e "${YELLOW}🚪 Выход.${RESET}" ;;
  *) echo -e "${YELLOW}❓ Неверный выбор${RESET}" ;;
esac

