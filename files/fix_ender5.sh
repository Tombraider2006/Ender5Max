#!/bin/sh

PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
GCODE_MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"

backup_files() {
    echo "📦 Создание резервных копий..."
    [ ! -f "${PRINTER_CFG}.bak" ] && cp "$PRINTER_CFG" "${PRINTER_CFG}.bak"
    [ ! -f "${GCODE_MACRO_CFG}.bak" ] && cp "$GCODE_MACRO_CFG" "${GCODE_MACRO_CFG}.bak"
}

restore_files() {
    echo "♻️ Восстановление файлов..."
    [ -f "${PRINTER_CFG}.bak" ] && mv -f "${PRINTER_CFG}.bak" "$PRINTER_CFG"
    [ -f "${GCODE_MACRO_CFG}.bak" ] && mv -f "${GCODE_MACRO_CFG}.bak" "$GCODE_MACRO_CFG"
}

apply_printer_cfg_fixes() {
    echo "🛠 Правим printer.cfg..."

    # 1. Height_module2 → _Height_module2
    sed -i 's/\[output_pin Height_module2\]/[output_pin _Height_module2]/' "$PRINTER_CFG"

    # 2. Блок light_pin
    sed -i '/\[output_pin light_pin\]/,/value: 0.0/d' "$PRINTER_CFG"
    cat <<'EOF' >> "$PRINTER_CFG"

[output_pin light_pin] # освещение камеры принтера. косяк прошивки креалити.
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0

EOF

    # 3. MainBoardFan → MCU_fan
    sed -i '/\[output_pin MainBoardFan\]/,/pin: !PB1/d' "$PRINTER_CFG"
    cat <<'EOF' >> "$PRINTER_CFG"

[controller_fan MCU_fan] # включаем обдув после включения драйверов
pin: PB1
max_power: 1.0
fan_speed: 1
kick_start_time: 0
stepper: stepper_x

EOF

    # 4. Замена блоков part_fans
    sed -i '/###喷头前面风扇/,/###喷头后面风扇/d' "$PRINTER_CFG"
    cat <<'EOF' >> "$PRINTER_CFG"

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
}

apply_gcode_macro_fixes() {
    echo "🛠 Правим gcode_macro.cfg..."

    # Удаляем старые блоки M106/M107
    sed -i '/\[gcode_macro M106\]/,/^\s*$/d' "$GCODE_MACRO_CFG"
    sed -i '/\[gcode_macro M107\]/,/^\s*$/d' "$GCODE_MACRO_CFG"

    # Добавляем новые макросы
    cat <<'EOF' >> "$GCODE_MACRO_CFG"

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
}

show_menu() {
    clear
    echo "========================================"
    echo "🚀 Tom Tomich Script (Ender-5 Max Fix)"
    echo -e "\033[1;34m\033[5m⚠️ Вносить изменения только после установки Helper Script (1,2,3,4,5,10)\033[0m"
    echo "========================================"

    if [ -f "${PRINTER_CFG}.bak" ] || [ -f "${GCODE_MACRO_CFG}.bak" ]; then
        echo -e "[1] \033[1;31mУстановить исправления (недоступно)\033[0m"
        echo -e "[2] \033[1;32mОткатить исправления\033[0m"
    else
        echo -e "[1] \033[1;32mУстановить исправления\033[0m"
        echo -e "[2] \033[1;31mОткатить исправления (недоступно)\033[0m"
    fi
    echo "[3] Выйти"
}

while true; do
    show_menu
    read -p "Выберите действие: " choice

    case $choice in
        1)
            if [ -f "${PRINTER_CFG}.bak" ] || [ -f "${GCODE_MACRO_CFG}.bak" ]; then
                echo "⚠️ Исправления уже применены."
                read -p "Нажмите Enter..."
            else
                backup_files
                apply_printer_cfg_fixes
                apply_gcode_macro_fixes
                echo "✅ Исправления установлены."
                read -p "Нажмите Enter..."
            fi
            ;;
        2)
            if [ -f "${PRINTER_CFG}.bak" ] || [ -f "${GCODE_MACRO_CFG}.bak" ]; then
                restore_files
                echo "♻️ Исправления откатены."
                read -p "Нажмите Enter..."
            else
                echo "⚠️ Нет резервных копий для отката."
                read -p "Нажмите Enter..."
            fi
            ;;
        3)
            echo "👋 Выход."
            exit 0
            ;;
        *)
            echo "❌ Неверный выбор."
            sleep 1
            ;;
    esac
done
