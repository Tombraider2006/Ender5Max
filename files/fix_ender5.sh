#!/bin/sh
set -u

# ================================
#   Tom Tomich Script v4.0
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
  printf "%b\n" "${YELLOW}🚀 Tom Tomich Script v4.0 (Nebula Pad)${RESET}"
  printf "%b\n" "${YELLOW} Helper & Fix Tool for Ender-5 Max${RESET}"
  printf "%b\n" "${YELLOW}========================================${RESET}"
  echo ""
}

confirm_action() {
  printf "Вы уверены? (y/n): "
  read ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ]
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

  # Подключаем функции из tools.sh (log_action и т.п.)
  if [ -f "$HELPER_DIR/scripts/tools.sh" ]; then
    . "$HELPER_DIR/scripts/tools.sh"
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
is_installed_e5mfix() { [ -f "$PRINTER_BAK" ] && [ -f "$MACRO_BAK" ]; }

# Вызовы install/remove с log_action
install_moonraker() {
  log_action "Установка Moonraker..."
  sh "$HELPER_DIR/scripts/moonraker_nginx.sh"
  log_action "Установка Moonraker завершена"
  read -p "Нажмите Enter..."
}
remove_moonraker() {
  log_action "Удаление Moonraker..."
  sh "$HELPER_DIR/scripts/moonraker_nginx.sh" remove
  log_action "Удаление Moonraker завершено"
  read -p "Нажмите Enter..."
}

install_fluidd() {
  log_action "Установка Fluidd..."
  sh "$HELPER_DIR/scripts/fluidd.sh"
  log_action "Установка Fluidd завершена"
  read -p "Нажмите Enter..."
}
remove_fluidd() {
  log_action "Удаление Fluidd..."
  sh "$HELPER_DIR/scripts/fluidd.sh" remove
  log_action "Удаление Fluidd завершено"
  read -p "Нажмите Enter..."
}

install_mainsail() {
  log_action "Установка Mainsail..."
  sh "$HELPER_DIR/scripts/mainsail.sh"
  log_action "Установка Mainsail завершена"
  read -p "Нажмите Enter..."
}
remove_mainsail() {
  log_action "Удаление Mainsail..."
  sh "$HELPER_DIR/scripts/mainsail.sh" remove
  log_action "Удаление Mainsail завершено"
  read -p "Нажмите Enter..."
}

install_entware() {
  log_action "Установка Entware..."
  sh "$HELPER_DIR/scripts/entware.sh"
  log_action "Установка Entware завершена"
  read -p "Нажмите Enter..."
}
remove_entware() {
  log_action "Удаление Entware..."
  sh "$HELPER_DIR/scripts/entware.sh" remove
  log_action "Удаление Entware завершено"
  read -p "Нажмите Enter..."
}

install_shell() {
  log_action "Включение Klipper Gcode Shell Command..."
  sh "$HELPER_DIR/scripts/gcode_shell_command.sh"
  log_action "Включение завершено"
  read -p "Нажмите Enter..."
}
remove_shell() {
  log_action "Выключение Klipper Gcode Shell Command..."
  sh "$HELPER_DIR/scripts/gcode_shell_command.sh" remove
  log_action "Выключение завершено"
  read -p "Нажмите Enter..."
}

install_shapers() {
  log_action "Установка Improved Shapers Calibrations..."
  sh "$HELPER_DIR/scripts/improved_shapers.sh"
  log_action "Установка завершена"
  read -p "Нажмите Enter..."
}
remove_shapers() {
  log_action "Удаление Improved Shapers Calibrations..."
  sh "$HELPER_DIR/scripts/improved_shapers.sh" remove
  log_action "Удаление завершено"
  read -p "Нажмите Enter..."
}

# ---------- Исправления Ender-5 Max ----------
fix_e5m() {
  echo "⚙️ Применяются исправления Ender-5 Max..."
  cp -p "$PRINTER_CFG" "$PRINTER_BAK"
  cp -p "$MACRO_CFG" "$MACRO_BAK"
  echo "📂 Созданы бэкапы."

  # Чистим старые секции
  sed -i '/\[firmware_retraction\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_shell_command beep\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_macro BEEP\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[delayed_gcode light_init\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[exclude_object\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_macro PID_BED\]/,/^$/d' "$MACRO_CFG"
  sed -i '/\[gcode_macro PID_HOTEND\]/,/^$/d' "$MACRO_CFG"

  # Добавляем новые секции
  cat >> "$MACRO_CFG" <<'EOF'

[firmware_retraction]
retract_length: 0.45
retract_speed: 30
unretract_extra_length: 0
unretract_speed: 30

[gcode_shell_command beep]
command: beep
timeout: 2
verbose: False

[gcode_macro BEEP]
description: Play a sound
gcode:
  RUN_SHELL_COMMAND CMD=beep

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
EOF

  echo "✅ Исправления для Ender-5 Max применены."
  restart_klipper
  read -p "Нажмите Enter..."
}

restore_e5m() {
  echo "♻️ Восстанавливаются бэкапы Ender-5 Max..."
  if [ -f "$PRINTER_BAK" ] && [ -f "$MACRO_BAK" ]; then
    cp -p "$PRINTER_BAK" "$PRINTER_CFG"
    cp -p "$MACRO_BAK" "$MACRO_CFG"
    echo "📂 Конфиги восстановлены."
    rm -f "$PRINTER_BAK" "$MACRO_BAK"
    restart_klipper
    echo "✅ Восстановление завершено."
  else
    echo "❗ Бэкапы не найдены."
  fi
  read -p "Нажмите Enter..."
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
    read choice
    case "$choice" in
      1) if confirm_action; then install_moonraker; fi;;
      2) if confirm_action; then install_fluidd; fi;;
      3) if confirm_action; then install_mainsail; fi;;
      4) if confirm_action; then install_entware; fi;;
      5) if confirm_action; then install_shell; fi;;
      6) if confirm_action; then install_shapers; fi;;
      8) if confirm_action; then fix_e5m; fi;;
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
    if is_installed_e5mfix; then printf "[7] %b\n" "${GREEN}🟢 Откатить исправления Ender-5 Max${RESET}"; else printf "[7] %b\n" "${RED}🔴 Откатить исправления Ender-5 Max${RESET}"; fi
    echo "[b] Назад в главное меню"
    echo ""
    printf "Выберите действие: "
    read choice
    case "$choice" in
      1) if confirm_action; then remove_moonraker; fi;;
      2) if confirm_action; then remove_fluidd; fi;;
      3) if confirm_action; then remove_mainsail; fi;;
      4) if confirm_action; then remove_entware; fi;;
      5) if confirm_action; then remove_shell; fi;;
      6) if confirm_action; then remove_shapers; fi;;
      7) if confirm_action; then restore_e5m; fi;;
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
  read choice
  case "$choice" in
    1) menu_install ;;
    2) menu_remove ;;
    q|Q) echo "Выход..." ; exit 0 ;;
  esac
done
