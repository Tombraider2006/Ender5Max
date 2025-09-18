#!/bin/sh

CFG="/usr/data/printer_data/config/printer.cfg"
BAK="${CFG}.bak"

# Делаем бэкап
cp -p "$CFG" "$BAK"

# 1. [output_pin Height_module2] → [output_pin _Height_module2]
sed -i 's/^\[output_pin Height_module2\]/[output_pin _Height_module2]/' "$CFG"

# 2. Блок light_pin заменяем
sed -i '/^\[output_pin light_pin\]/,/^$/d' "$CFG"
cat >> "$CFG" <<'EOF'

[output_pin light_pin] #  освещение камеры принтера. косяк прошивки креалити.
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0
EOF

# 3. MainBoardFan → controller_fan MCU_fan
sed -i '/^\[output_pin MainBoardFan\]/,/^$/d' "$CFG"
cat >> "$CFG" <<'EOF'

[controller_fan MCU_fan] # включаем обдув после включения драйверов
pin: PB1
max_power: 1.0
fan_speed: 1
kick_start_time: 0
stepper: stepper_x
EOF

# 4. Удаляем фан0 и фан1 блоки (с китайскими комментариями)
sed -i '/^###喷头前面风扇/,/^###喷头后面风扇/d' "$CFG"
sed -i '/^\[output_pin fan1\]/,/^$/d' "$CFG"
sed -i '/^\[output_pin en_fan1\]/,/^$/d' "$CFG"

# 5. Вставляем новые multi_pin и fan_generic
cat >> "$CFG" <<'EOF'

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

echo "✅ Изменения внесены. Бэкап: $BAK"

