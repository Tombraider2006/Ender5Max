#!/bin/bash
set -u

# fix_ender5.sh
# Удаляет старые блоки и вставляет новые корректные блоки в printer.cfg и gcode_macro.cfg
# Путь к файлам жёстко задан:
PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"
PRINTER_BAK="${PRINTER_CFG}.bak"
MACRO_BAK="${MACRO_CFG}.bak"

usage() {
  echo "Использование:"
  echo "  $0            # внести правки (создаст .bak перед изменениями)"
  echo "  $0 --restore  # восстановить файлы из .bak"
  exit 1
}

if [[ "${1:-}" == "--restore" ]]; then
  if [[ -f "$PRINTER_BAK" && -f "$MACRO_BAK" ]]; then
    cp -p "$PRINTER_BAK" "$PRINTER_CFG"
    cp -p "$MACRO_BAK" "$MACRO_CFG"
    echo "♻️  Конфиги восстановлены из бэкапов:"
    echo "    $PRINTER_BAK -> $PRINTER_CFG"
    echo "    $MACRO_BAK -> $MACRO_CFG"
    exit 0
  else
    echo "❗ Бэкапы не найдены:"
    echo "   $PRINTER_BAK"
    echo "   $MACRO_BAK"
    exit 2
  fi
fi

# Проверки
if [[ ! -f "$PRINTER_CFG" ]]; then
  echo "❗ Не найден $PRINTER_CFG"
  exit 3
fi
if [[ ! -f "$MACRO_CFG" ]]; then
  echo "❗ Не найден $MACRO_CFG"
  exit 4
fi

# Создаём бэкапы
cp -p "$PRINTER_CFG" "$PRINTER_BAK"
cp -p "$MACRO_CFG" "$MACRO_BAK"
echo "📂 Созданы бэкапы:"
echo "   $PRINTER_BAK"
echo "   $MACRO_BAK"

# ---------------------------
# printer.cfg — УДАЛЕНИЕ старых блоков (несколько попыток)
# ---------------------------

# 1) Height_module2 — простая замена в строке
sed -i 's/^\[output_pin Height_module2\]/[output_pin _Height_module2]/' "$PRINTER_CFG" \
  && echo "🔁 Заменён [output_pin Height_module2] -> [output_pin _Height_module2]"

# 2) Удаляем любые старые определения light_pin
sed -i '/^\[output_pin light_pin\]/,/^$/d' "$PRINTER_CFG"   # удаляем до пустой строки (если есть)
sed -i '/^\[output_pin light_pin\]/,/^\[/d' "$PRINTER_CFG" # запасной вариант — до следующего заголовка
echo "🗑 Удалены старые блоки [output_pin light_pin] (если были)"

# 3) Удаляем старые определения MainBoardFan (если есть)
sed -i '/^\[output_pin MainBoardFan\]/,/^$/d' "$PRINTER_CFG"
sed -i '/^\[output_pin MainBoardFan\]/,/^\[/d' "$PRINTER_CFG"
echo "🗑 Удалены старые блоки [output_pin MainBoardFan] (если были)"

# 4) Удаляем старые блоки вентиляторов (fan0, en_fan0, fan1, en_fan1)
sed -i '/^\[output_pin fan0\]/,/^$/d' "$PRINTER_CFG"
sed -i '/^\[output_pin en_fan0\]/,/^$/d' "$PRINTER_CFG"
sed -i '/^\[output_pin fan1\]/,/^$/d' "$PRINTER_CFG"
sed -i '/^\[output_pin en_fan1\]/,/^$/d' "$PRINTER_CFG"
# Запасные варианты на случай отсутствия пустой строки
sed -i '/^\[output_pin fan0\]/,/^\[/d' "$PRINTER_CFG"
sed -i '/^\[output_pin en_fan0\]/,/^\[/d' "$PRINTER_CFG"
sed -i '/^\[output_pin fan1\]/,/^\[/d' "$PRINTER_CFG"
sed -i '/^\[output_pin en_fan1\]/,/^\[/d' "$PRINTER_CFG"
echo "🗑 Удалены старые блоки вентиляторов fan0/en_fan0/fan1/en_fan1 (если были)"

# Удаляем возможные старые вставки multi_pin/part_fans и контроллеры (чтобы не дублировать)
sed -i '/^\[multi_pin part_fans\]/,/^$/d' "$PRINTER_CFG"
sed -i '/^\[multi_pin en_part_fans\]/,/^$/d' "$PRINTER_CFG"
sed -i '/^\[fan_generic part\]/,/^$/d' "$PRINTER_CFG"
sed -i '/^\[controller_fan MCU_fan\]/,/^$/d' "$PRINTER_CFG"
# запасные:
sed -i '/^\[multi_pin part_fans\]/,/^\[/d' "$PRINTER_CFG"
sed -i '/^\[multi_pin en_part_fans\]/,/^\[/d' "$PRINTER_CFG"
sed -i '/^\[fan_generic part\]/,/^\[/d' "$PRINTER_CFG"
sed -i '/^\[controller_fan MCU_fan\]/,/^\[/d' "$PRINTER_CFG"

# ---------------------------
# printer.cfg — ДОБАВЛЕНИЕ новых блоков (в конец файла)
# ---------------------------

# Добавляем блок light_pin (после удаления старого — безопасно)
cat <<'EOF' >> "$PRINTER_CFG"

[output_pin light_pin] # освещение камеры принтера. косяк прошивки креалити.
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0
EOF
echo "➕ Добавлен новый блок [output_pin light_pin]"

# Добавляем controller_fan заменяющий MainBoardFan
cat <<'EOF' >> "$PRINTER_CFG"

[controller_fan MCU_fan] # включаем обдув после включения драйверов
pin: PB1
max_power: 1.0
fan_speed: 1
kick_start_time: 0
stepper: stepper_x
EOF
echo "➕ Добавлен блок [controller_fan MCU_fan]"

# Добавляем multi_pin + fan_generic (для замены старых fan0/fan1)
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
echo "➕ Добавлены [multi_pin part_fans], [multi_pin en_part_fans], [fan_generic part]"

# ---------------------------
# gcode_macro.cfg — УДАЛЕНИЕ старых макросов
# ---------------------------

# Удаляем старые определения M106 и M107 и связанные (по пустой строке и запасной по следующему заголовку)
sed -i '/^\[gcode_macro M106\]/,/^$/d' "$MACRO_CFG"
sed -i '/^\[gcode_macro M107\]/,/^$/d' "$MACRO_CFG"
sed -i '/^\[gcode_macro TURN_OFF_FANS\]/,/^$/d' "$MACRO_CFG"
sed -i '/^\[gcode_macro TURN_ON_FANS\]/,/^$/d' "$MACRO_CFG"
# запасные варианты
sed -i '/^\[gcode_macro M106\]/,/^\[/d' "$MACRO_CFG"
sed -i '/^\[gcode_macro M107\]/,/^\[/d' "$MACRO_CFG"
sed -i '/^\[gcode_macro TURN_OFF_FANS\]/,/^\[/d' "$MACRO_CFG"
sed -i '/^\[gcode_macro TURN_ON_FANS\]/,/^\[/d' "$MACRO_CFG"
echo "🗑 Удалены старые макросы M106/M107/TURN_OFF_FANS/TURN_ON_FANS (если были)"

# Удаляем строки переменных
sed -i '/^variable_fan0_min:/d' "$MACRO_CFG"
sed -i '/^variable_fan1_min:/d' "$MACRO_CFG"
echo "🗑 Удалены variable_fan0_min / variable_fan1_min (если были)"

# ---------------------------
# gcode_macro.cfg — ДОБАВЛЕНИЕ новых макросов (в конец файла)
# ---------------------------

cat <<'EOF' >> "$MACRO_CFG"

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
echo "➕ Добавлены новые макросы M106/M107/TURN_OFF_FANS/TURN_ON_FANS"

echo "✅ Все правки внесены. Файлы:"
echo "   $PRINTER_CFG"
echo "   $MACRO_CFG"
echo ""
echo "Рекомендации:"
echo "  - Проверьте изменения: diff $PRINTER_BAK $PRINTER_CFG | head -n 100"
echo "  - Перезагрузите Klipper/принтер после правок."
