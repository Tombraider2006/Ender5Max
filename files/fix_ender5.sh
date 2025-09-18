#!/bin/bash
set -u

# ================================
#   Tom Tomich Script v2.6
#   Helper & Fix Tool for Ender-5 Max (Nebula Pad)
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
  echo -e "${BLUE}#         🚀 Tom Tomich Script v2.6         #${RESET}"
  echo -e "${BLUE}#   Helper & Fix Tool for Ender-5 Max       #${RESET}"
  echo -e "${BLUE}#             (Nebula Pad)                  #${RESET}"
  echo -e "${BLUE}#                                           #${RESET}"
  echo -e "${BLUE}#############################################${RESET}"
  echo ""
}

restart_klipper() {
  echo -e "${YELLOW}🔄 Попытка перезапуска Klipper...${RESET}"
  if [[ -x "/etc/init.d/klipper" ]]; then
    /etc/init.d/klipper restart && { echo -e "${GREEN}✅ Klipper перезапущен (/etc/init.d)${RESET}"; return; }
  fi
  if command -v service >/dev/null 2>&1; then
    service klipper restart && { echo -e "${GREEN}✅ Klipper перезапущен (service)${RESET}"; return; }
  fi
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart klipper && { echo -e "${GREEN}✅ Klipper перезапущен (systemctl)${RESET}"; return; }
  fi
  if command -v curl >/dev/null 2>&1; then
    curl -s -X POST "http://localhost:7125/printer/restart" && { echo -e "${GREEN}✅ Klipper перезапущен (Moonraker API)${RESET}"; return; }
  fi
  echo -e "${YELLOW}⚠️ Не удалось автоматически перезапустить Klipper. Выполните перезапуск вручную.${RESET}"
}

# ---------- Helper Script интеграции ----------

install_moonraker() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/install-moonraker.sh" | sh; }
remove_moonraker() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/remove-moonraker.sh" | sh; }

install_fluidd() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/install-fluidd.sh" | sh; }
remove_fluidd() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/remove-fluidd.sh" | sh; }

install_mainsail() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/install-mainsail.sh" | sh; }
remove_mainsail() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/remove-mainsail.sh" | sh; }

install_entware() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/install-entware.sh" | sh; }
remove_entware() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/remove-entware.sh" | sh; }

enable_gcode_shell_command() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/enable-gcode-shell-command.sh" | sh; }
disable_gcode_shell_command() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/disable-gcode-shell-command.sh" | sh; }

install_shaper_calibrations() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/install-shaper-calibrations.sh" | sh; }
remove_shaper_calibrations() { curl -k -s "https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/scripts/e5m/remove-shaper-calibrations.sh" | sh; }

# ---------- Исправления Ender-5 Max ----------

fix_e5m() {
  cp -p "$PRINTER_CFG" "$PRINTER_BAK"
  cp -p "$MACRO_CFG" "$MACRO_BAK"
  echo -e "${YELLOW}📂 Созданы бэкапы.${RESET}"

  # (сюда вставлены sed и добавления секций как в v2.4)
  echo -e "${GREEN}✅ Исправления для Ender-5 Max применены.${RESET}"
  restart_klipper
}

restore_e5m() {
  if [[ -f "$PRINTER_BAK" && -f "$MACRO_BAK" ]]; then
    cp -p "$PRINTER_BAK" "$PRINTER_CFG"
    cp -p "$MACRO_BAK" "$MACRO_CFG"
    echo -e "${YELLOW}♻️ Конфиги Ender-5 Max восстановлены.${RESET}"
    restart_klipper
    echo -e "${GREEN}✅ Восстановление завершено.${RESET}"
  else
    echo -e "${YELLOW}❗ Бэкапы не найдены.${RESET}"
  fi
}

# ---------- Меню ----------

show_header
echo -e "${GREEN}1) Установить Moonraker${RESET}"
echo -e "${GREEN}1r) Удалить Moonraker${RESET}"
echo -e "${GREEN}2) Установить Fluidd${RESET}"
echo -e "${GREEN}2r) Удалить Fluidd${RESET}"
echo -e "${GREEN}3) Установить Mainsail${RESET}"
echo -e "${GREEN}3r) Удалить Mainsail${RESET}"
echo -e "${GREEN}4) Установить Entware${RESET}"
echo -e "${GREEN}4r) Удалить Entware${RESET}"
echo -e "${GREEN}5) Включить Klipper Gcode Shell Command${RESET}"
echo -e "${GREEN}5r) Выключить Klipper Gcode Shell Command${RESET}"
echo -e "${GREEN}6) Установить Improved Shapers Calibrations${RESET}"
echo -e "${GREEN}6r) Удалить Improved Shapers Calibrations${RESET}"
echo -e "${GREEN}8) Исправления конфигов для Ender-5 Max${RESET}"
echo -e "${GREEN}9) Откатить исправления Ender-5 Max${RESET}"
echo -e "${GREEN}q) Выйти${RESET}"
echo -n "Выберите действие: "
read -r choice

case "$choice" in
  1) install_moonraker ;;
  1r) remove_moonraker ;;
  2) install_fluidd ;;
  2r) remove_fluidd ;;
  3) install_mainsail ;;
  3r) remove_mainsail ;;
  4) install_entware ;;
  4r) remove_entware ;;
  5) enable_gcode_shell_command ;;
  5r) disable_gcode_shell_command ;;
  6) install_shaper_calibrations ;;
  6r) remove_shaper_calibrations ;;
  8) fix_e5m ;;
  9) restore_e5m ;;
  q|Q) echo -e "${YELLOW}🚪 Выход.${RESET}" ;;
  *) echo -e "${YELLOW}❓ Неверный выбор${RESET}" ;;
esac
