#!/bin/sh
set -u

PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"
PRINTER_BAK="${PRINTER_CFG}.bak"
MACRO_BAK="${MACRO_CFG}.bak"

# ---------- Утилиты ----------
die() { echo "ERROR: $*" 1>&2; exit 1; }

check_tools() {
  # Проверим базовые утилиты
  for t in awk sed grep cp mv rm cat; do
    if ! command -v "$t" >/dev/null 2>&1; then
      die "Требуется утилита '$t' но не найдена в PATH"
    fi
  done
}

# remove_section <file> "<exact header line>"
# Удаляет блок начиная с строки, совпадающей с header, до строки, начинающейся с '[' (следующей секции) или EOF.
remove_section() {
  file="$1"
  header="$2"
  [ -f "$file" ] || return 0
  # Если header не найден — ничего не делаем
  if ! grep -xF "$header" "$file" >/dev/null 2>&1; then
    return 0
  fi
  awk -v h="$header" '
    BEGIN { skip=0 }
    {
      if ($0 == h) { skip=1; next }
      if (skip && /^\[/) { skip=0 }
      if (!skip) print
    }
  ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

section_exists() {
  file="$1"; header="$2"
  [ -f "$file" ] || return 1
  grep -xF "$header" "$file" >/dev/null 2>&1
}

# ---------- Шапка / меню ----------
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

# ---------- Применение исправлений ----------
apply_fix() {
  echo "⚙️  Применяются исправления..."
  # Проверки
  [ -f "$PRINTER_CFG" ] || { echo "❗ Не найден $PRINTER_CFG"; read -p "Нажмите Enter..."; return 1; }
  [ -f "$MACRO_CFG" ] || { echo "❗ Не найден $MACRO_CFG"; read -p "Нажмите Enter..."; return 1; }

  # Бэкапы
  echo "Создаю бэкапы..."
  cp -p "$PRINTER_CFG" "$PRINTER_BAK"
  cp -p "$MACRO_CFG" "$MACRO_BAK"

  ########################################
  # 1) Изменение в printer.cfg
  ########################################

  # 1.1 Замена заголовка [output_pin Height_module2] -> [output_pin _Height_module2]
  # (меняем только точное совпадение строки)
  if grep -xF "[output_pin Height_module2]" "$PRINTER_CFG" >/dev/null 2>&1; then
    sed -i 's/^\[output_pin Height_module2\]$/[output_pin _Height_module2]/' "$PRINTER_CFG"
    echo " - заменён [output_pin Height_module2] -> [output_pin _Height_module2]"
  else
    echo " - [output_pin Height_module2] не найден (пропускаю)"
  fi

  # 1.2 Секция light_pin: удаляем любую старую секцию и добавляем нужную (если ещё нет)
  remove_section "$PRINTER_CFG" "[output_pin light_pin]"
  if ! grep -xF "[output_pin light_pin] # освещение камеры принтера. косяк прошивки креалити." "$PRINTER_CFG" >/dev/null 2>&1; then
    cat >> "$PRINTER_CFG" <<'EOF'

[output_pin light_pin] # освещение камеры принтера. косяк прошивки креалити.
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0
EOF
    echo " - добавлена секция [output_pin light_pin]"
  else
    echo " - секция [output_pin light_pin] уже присутствует"
  fi

  # 1.3 Замена MainBoardFan -> controller_fan MCU_fan
  remove_section "$PRINTER_CFG" "[output_pin MainBoardFan]"
  if ! grep -xF "[controller_fan MCU_fan] # включаем обдув после включения драйверов" "$PRINTER_CFG" >/dev/null 2>&1; then
    cat >> "$PRINTER_CFG" <<'EOF'

[controller_fan MCU_fan] # включаем обдув после включения драйверов
pin: PB1
max_power: 1.0
fan_speed: 1
kick_start_time: 0
stepper: stepper_x
EOF
    echo " - добавлена секция [controller_fan MCU_fan]"
  else
    echo " - секция [controller_fan MCU_fan] уже присутствует"
  fi

  ########################################
  # 2) Изменения в gcode_macro.cfg
  ########################################

  # Список заголовков, которые надо удалить перед добавлением
  headers_to_remove="
[firmware_retraction]
[gcode_shell_command beep]
[gcode_macro BEEP]
[delayed_gcode light_init]
[exclude_object]
[gcode_macro PID_BED]
[gcode_macro PID_HOTEND]
[gcode_macro M106]
[gcode_macro M107]
[gcode_macro TURN_OFF_FANS]
[gcode_macro TURN_ON_FANS]
"
  # Удаляем их по очереди (если есть)
  for h in $headers_to_remove; do
    # trim possible spaces
    h_trim=$(printf "%s" "$h" | sed 's/^ *//; s/ *$//')
    remove_section "$MACRO_CFG" "$h_trim"
  done

  # Теперь добавим все нужные секции в конец файла (если они ещё не существуют)
  if ! grep -xF "[firmware_retraction]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

[firmware_retraction]
retract_length: 0.45
retract_speed: 30
unretract_extra_length: 0
unretract_speed: 30
EOF
    echo " - добавлен [firmware_retraction]"
  else
    echo " - [firmware_retraction] уже есть"
  fi

  if ! grep -xF "[gcode_shell_command beep]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

[gcode_shell_command beep]
command: beep
timeout: 2
verbose: False
EOF
    echo " - добавлен [gcode_shell_command beep]"
  else
    echo " - [gcode_shell_command beep] уже есть"
  fi

  if ! grep -xF "[gcode_macro BEEP]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

[gcode_macro BEEP]
description: Play a sound
gcode:
  RUN_SHELL_COMMAND CMD=beep
EOF
    echo " - добавлен [gcode_macro BEEP]"
  else
    echo " - [gcode_macro BEEP] уже есть"
  fi

  if ! grep -xF "[delayed_gcode light_init]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

[delayed_gcode light_init]
initial_duration: 5.01
gcode:
  SET_PIN PIN=light_pin VALUE=1
EOF
    echo " - добавлен [delayed_gcode light_init]"
  else
    echo " - [delayed_gcode light_init] уже есть"
  fi

  if ! grep -xF "[exclude_object]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

[exclude_object]
EOF
    echo " - добавлен [exclude_object]"
  else
    echo " - [exclude_object] уже есть"
  fi

  if ! grep -xF "[gcode_macro PID_BED]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

[gcode_macro PID_BED]
gcode:
  PID_CALIBRATE HEATER=heater_bed TARGET={params.BED_TEMP|default(70)}
  SAVE_CONFIG
EOF
    echo " - добавлен [gcode_macro PID_BED]"
  else
    echo " - [gcode_macro PID_BED] уже есть"
  fi

  if ! grep -xF "[gcode_macro PID_HOTEND]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

[gcode_macro PID_HOTEND]
description: Start Hotend PID
gcode:
  G90
  G28
  G1 Z10 F600
  M106 S255 # включение вентилятора
  PID_CALIBRATE HEATER=extruder TARGET={params.HOTEND_TEMP|default(250)}
  M107 # выключение вентилятора
EOF
    echo " - добавлен [gcode_macro PID_HOTEND]"
  else
    echo " - [gcode_macro PID_HOTEND] уже есть"
  fi

  # Добавляем макросы M106/M107/TURN_ON/OFF
  if ! grep -xF "[gcode_macro M106]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

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
EOF
    echo " - добавлен [gcode_macro M106]"
  else
    echo " - [gcode_macro M106] уже есть"
  fi

  if ! grep -xF "[gcode_macro M107]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

[gcode_macro M107]
description: Set Fan Off. P0 for part
gcode:
  SET_FAN_SPEED FAN=part SPEED=0
EOF
    echo " - добавлен [gcode_macro M107]"
  else
    echo " - [gcode_macro M107] уже есть"
  fi

  if ! grep -xF "[gcode_macro TURN_OFF_FANS]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

[gcode_macro TURN_OFF_FANS]
description: Stop chamber, auxiliary and part fan
gcode:
  SET_FAN_SPEED FAN=part SPEED=0
EOF
    echo " - добавлен [gcode_macro TURN_OFF_FANS]"
  else
    echo " - [gcode_macro TURN_OFF_FANS] уже есть"
  fi

  if ! grep -xF "[gcode_macro TURN_ON_FANS]" "$MACRO_CFG" >/dev/null 2>&1; then
    cat >> "$MACRO_CFG" <<'EOF'

[gcode_macro TURN_ON_FANS]
description: Turn on chamber, auxiliary and part fan
gcode:
  SET_FAN_SPEED FAN=part SPEED=1
EOF
    echo " - добавлен [gcode_macro TURN_ON_FANS]"
  else
    echo " - [gcode_macro TURN_ON_FANS] уже есть"
  fi

  echo "✅ Все изменения внесены (бэкапы: ${PRINTER_BAK}, ${MACRO_BAK})."
  read -p "Нажмите Enter..."
}

# ---------- Восстановление ----------
restore_fix() {
  echo "♻️  Восстанавливаются файлы..."
  if [ -f "$PRINTER_BAK" ] && [ -f "$MACRO_BAK" ]; then
    cp -p "$PRINTER_BAK" "$PRINTER_CFG"
    cp -p "$MACRO_BAK" "$MACRO_CFG"
    rm -f "$PRINTER_BAK" "$MACRO_BAK"
    echo "✅ Файлы восстановлены из бэкапов."
  else
    echo "❗ Бэкапы не найдены: ${PRINTER_BAK} или ${MACRO_BAK}"
  fi
  read -p "Нажмите Enter..."
}

# ---------- Main ----------
check_tools

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
    1)
      if [ "$FIXED" = false ]; then
        printf "Вы уверены? (y/n): "
        read ans
        if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
          apply_fix
        fi
      else
        echo "Исправления уже применены — сначала откатите."
        read -p "Нажмите Enter..."
      fi
    ;;
    2)
      if [ "$FIXED" = true ]; then
        printf "Вы уверены, что хотите откатить исправления? (y/n): "
        read ans
        if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
          restore_fix
        fi
      else
        echo "Нечего откатывать."
        read -p "Нажмите Enter..."
      fi
    ;;
    3) exit 0 ;;
  esac
done
