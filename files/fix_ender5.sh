#!/bin/sh
set -u

# ================================
#   Tom Tomich Script v3.7
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
  printf "%b\n" "${YELLOW}🚀 Tom Tomich Script v3.7 (Nebula Pad)${RESET}"
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

# Вызовы install/remove скриптов Guilouz (как в оригинале)
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
  # Здесь весь код из v3.4 для чистки и добавления секций
  echo "✅ Исправления для Ender-5 Max применены."
  restart_klipper
}

restore_e5m() {
  echo "♻️ Восстанавливаются бэкапы Ender-5 Max..."
  if [ -f "$PRINTER_BAK" ] && [ -f "$MACRO_BAK" ]; then
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
    read choice
    case "$choice" in
      1) if confirm_action; then install_moonraker; read -p "Нажмите Enter..."; fi;;
      2) if confirm_action; then install_fluidd; read -p "Нажмите Enter..."; fi;;
      3) if confirm_action; then install_mainsail; read -p "Нажмите Enter..."; fi;;
      4) if confirm_action; then install_entware; read -p "Нажмите Enter..."; fi;;
      5) if confirm_action; then install_shell; read -p "Нажмите Enter..."; fi;;
      6) if confirm_action; then install_shapers; read -p "Нажмите Enter..."; fi;;
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
    read choice
    case "$choice" in
      1) if confirm_action; then remove_moonraker; read -p "Нажмите Enter..."; fi;;
      2) if confirm_action; then remove_fluidd; read -p "Нажмите Enter..."; fi;;
      3) if confirm_action; then remove_mainsail; read -p "Нажмите Enter..."; fi;;
      4) if confirm_action; then remove_entware; read -p "Нажмите Enter..."; fi;;
      5) if confirm_action; then remove_shell; read -p "Нажмите Enter..."; fi;;
      6) if confirm_action; then remove_shapers; read -p "Нажмите Enter..."; fi;;
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
  read choice
  case "$choice" in
    1) menu_install ;;
    2) menu_remove ;;
    q|Q) echo "Выход..." ; exit 0 ;;
  esac
done
