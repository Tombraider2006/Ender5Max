#!/bin/sh
# ========================================
# 🚀 Tom Tomich Script (Ender-5 Max Fix)
# ========================================

# Пути к файлам
PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
GCODE_MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"

# Цвета
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

show_menu() {
    clear
printf "========================================\n"
printf "🚀 Tom Tomich Script (Ender-5 Max Fix)\n"
printf "========================================\n"
printf "${BLUE}⚠️  Вносить изменения только после установки Helper Script пунктов 1 (2 или 3), 4, 5, 10${RESET}\n\n"


    if [ -f "${PRINTER_CFG}.bak" ] || [ -f "${GCODE_MACRO_CFG}.bak" ]; then
        printf "[1] ${RED}Установить исправления (недоступно)${RESET}\n"
        printf "[2] ${GREEN}Откатить исправления${RESET}\n"
    else
        printf "[1] ${GREEN}Установить исправления${RESET}\n"
        printf "[2] ${RED}Откатить исправления (недоступно)${RESET}\n"
    fi

    printf "[3] Выйти\n\n"
    printf "Выберите действие: "
}


apply_fixes() {
    echo -e "${YELLOW}⚙️ Вносим исправления...${RESET}"

    # --- printer.cfg ---
    if [ ! -f "${PRINTER_CFG}.bak" ]; then
        cp -p "$PRINTER_CFG" "${PRINTER_CFG}.bak"
    fi

    # 1. Height_module2 → _Height_module2
    sed -i 's/^\[output_pin Height_module2\]/[output_pin _Height_module2]/' "$PRINTER_CFG"

    # 2. light_pin блок
    sed -i '/^\[output_pin light_pin\]/,/^$/d' "$PRINTER_CFG"
    cat >> "$PRINTER_CFG" <<'EOF'

[output_pin light_pin] #  освещение камеры принтера. косяк прошивки креалити.
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0
EOF

    # 3. MainBoardFan → controller_fan MCU_fan
    sed -i '/^\[output_pin MainBoardFan\]/,/^$/d' "$PRINTER_CFG"
    cat >> "$PRINTER_CFG" <<'EOF'

[controller_fan MCU_fan] # включаем обдув после включения драйверов
pin: PB1
max_power: 1.0
fan_speed: 1
kick_start_time: 0
stepper: stepper_x
EOF

    # 4. Удаляем fan0/fan1 и китайские комментарии
    sed -i '/^###喷头前面风扇/,/^$/d' "$PRINTER_CFG"
    sed -i '/^###喷头后面风扇/,/^$/d' "$PRINTER_CFG"
    sed -i '/^\[output_pin fan0\]/,/^$/d' "$PRINTER_CFG"
    sed -i '/^\[output_pin en_fan0\]/,/^$/d' "$PRINTER_CFG"
    sed -i '/^\[output_pin fan1\]/,/^$/d' "$PRINTER_CFG"
    sed -i '/^\[output_pin en_fan1\]/,/^$/d' "$PRINTER_CFG"

    # 5. Вставляем multi_pin + fan_generic
    cat >> "$PRINTER_CFG" <<'EOF'

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
    if [ ! -f "${GCODE_MACRO_CFG}.bak" ]; then
        cp -p "$GCODE_MACRO_CFG" "${GCODE_MACRO_CFG}.bak"
    fi

    # 1. Удаляем старые M106 и M107
    sed -i '/^\[gcode_macro M106\]/,/^\s*$/d' "$GCODE_MACRO_CFG"
    sed -i '/^\[gcode_macro M107\]/,/^\s*$/d' "$GCODE_MACRO_CFG"

    # 2. Добавляем новые
    cat >> "$GCODE_MACRO_CFG" <<'EOF'

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

    echo -e "${GREEN}✅ Исправления успешно внесены!${RESET}"
    read -p "Нажмите Enter для продолжения..."
}

rollback_fixes() {
    echo -e "${YELLOW}🔄 Выполняем откат исправлений...${RESET}"

    if [ -f "${PRINTER_CFG}.bak" ]; then
        mv "${PRINTER_CFG}.bak" "$PRINTER_CFG"
        echo -e "${GREEN}✅ printer.cfg восстановлен${RESET}"
    fi
    if [ -f "${GCODE_MACRO_CFG}.bak" ]; then
        mv "${GCODE_MACRO_CFG}.bak" "$GCODE_MACRO_CFG"
        echo -e "${GREEN}✅ gcode_macro.cfg восстановлен${RESET}"
    fi

    echo -e "${GREEN}✔️ Откат завершён.${RESET}"
    read -p "Нажмите Enter для продолжения..."
}

# --- Цикл меню ---
while true; do
    show_menu
    read choice
    case $choice in
        1) apply_fixes ;;
        2) rollback_fixes ;;
        3) exit 0 ;;
        *) echo -e "${RED}Неверный выбор!${RESET}"; sleep 1 ;;
    esac
done
