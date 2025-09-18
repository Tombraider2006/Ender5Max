#!/bin/sh

# ========================================
# 🚀 Tom Tomich Script (Ender-5 Max Fix)
# ========================================
# Вносить изменения только после установки helper script 1,2(или 3),4,5,10!
# ========================================

PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
GCODE_MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"

show_menu() {
    clear
    printf "========================================\n"
    printf "🚀 Tom Tomich Script (Ender-5 Max Fix)\n"
    printf "========================================\n\n"

    if [ -f "${PRINTER_CFG}.bak" ] || [ -f "${GCODE_MACRO_CFG}.bak" ]; then
        printf "[1] \033[1;31mУстановить исправления (уже установлено)\033[0m\n"
        printf "[2] \033[1;32mОткатить исправления\033[0m\n"
    else
        printf "[1] \033[1;32mУстановить исправления\033[0m\n"
        printf "[2] \033[1;31mОткатить исправления (недоступно)\033[0m\n"
    fi
    printf "[3] Выйти\n\n"
}

apply_fixes() {
    if [ -f "${PRINTER_CFG}.bak" ] || [ -f "${GCODE_MACRO_CFG}.bak" ]; then
        printf "❌ Исправления уже применены.\n"
        return
    fi

    cp "$PRINTER_CFG" "${PRINTER_CFG}.bak"
    cp "$GCODE_MACRO_CFG" "${GCODE_MACRO_CFG}.bak"

    # --- Printer.cfg fixes ---

    # [output_pin Height_module2] -> [output_pin _Height_module2]
    sed -i 's/^\[output_pin Height_module2\]/[output_pin _Height_module2]/' "$PRINTER_CFG"

    # Replace light_pin block
    sed -i '/\[output_pin light_pin\]/,/value: 0.0/d' "$PRINTER_CFG"
    cat <<'EOF' >> "$PRINTER_CFG"

[output_pin light_pin] # освещение камеры принтера. косяк прошивки креалити.
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0

EOF

    # Replace MainBoardFan with controller_fan MCU_fan
    sed -i '/\[output_pin MainBoardFan\]/,/stepper: stepper_x/d' "$PRINTER_CFG"
    cat <<'EOF' >> "$PRINTER_CFG"

[controller_fan MCU_fan] # включаем обдув после включения драйверов
pin: PB1
max_power: 1.0
fan_speed: 1
kick_start_time: 0
stepper: stepper_x

EOF

    # Replace fan0/fan1 blocks with multi_pin
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

    # --- gcode_macro.cfg fixes ---

    sed -i '/\[gcode_macro M106\]/,/^\s*$/d' "$GCODE_MACRO_CFG"
    sed -i '/\[gcode_macro M107\]/,/^\s*$/d' "$GCODE_MACRO_CFG"

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

    printf "✅ Исправления применены. Перезапустите Klipper.\n"
}

rollback_fixes() {
    if [ ! -f "${PRINTER_CFG}.bak" ] || [ ! -f "${GCODE_MACRO_CFG}.bak" ]; then
        printf "❌ Нет резервных файлов для отката.\n"
        return
    fi

    mv "${PRINTER_CFG}.bak" "$PRINTER_CFG"
    mv "${GCODE_MACRO_CFG}.bak" "$GCODE_MACRO_CFG"

    printf "♻️ Исправления откатены.\n"
}

while true; do
    show_menu
    read -p "Выберите действие: " choice
    case $choice in
        1) apply_fixes ;;
        2) rollback_fixes ;;
        3) exit 0 ;;
        *) printf "Неверный выбор.\n" ;;
    esac
    read -p "Нажмите Enter для продолжения..."
done
