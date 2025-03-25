<h3 align="right"><a href="https://www.tinkoff.ru/rm/yakovleva.irina203/51ZSr71845" target="_blank">ваше "спасибо" автору</a></h3>
<h3 align="right"><a href="https://t.me/tombraider2006" target="_blank">телеграм канал автора</a></h3>

<h2>мой конфиг</h2>

[**english version**](/config_my/readme_en.md)

Данный конфиг после! установки хелпер скрипта с моими правками. 

Если вы хотите повторить то сначала необходимо 

1. установить [хелпер скрипт](https://guilouz.github.io/Creality-Helper-Script-Wiki/helper-script/helper-script-installation/)
2. установить пункты те что отмечены зелеными галочками. 

3. после этого скачать файлы конфигурационные и заменить свои на мои. 

я бы на вашем месте свои файлы сохранил где то предварительно если что то пойдет не так всегда можно будет вернуть. после замены перезагружаем клиппер.

как может выглядеть интерфейс после установки.




https://github.com/user-attachments/assets/1851a861-b29d-4a3b-ac2f-7861f6cc0bae


Выложен для ознакомления и обсуждения.
![](/images/helper.png)

Внимание, для последних релизов необходим модуль virtual_pin. Для этого достаточно зайти по ssh и выполнить следующие команды;

```
cd /usr/share/klipper/klippy/extras
wget --no-check-certificate https://raw.githubusercontent.com/Tombraider2006/K1/main/random/virtual_pins.py

```
**Внимание!** это удалит текущие файлы printer.cfg gcode_macro.cfg и moonraker.conf из каталога. убедитесь что вы сделали бекап файлов на всякий случай. Делать это только после установки хелпер скрипта и тех пунктов в нем что указано выше!

загрузить последний релиз можно так: 

```
cd /usr/data/printer_data/config
rm printer.cfg
rm gcode_macro.cfg
rm moonraker.conf
wget --no-check-certificate https://raw.githubusercontent.com/Tombraider2006/Ender5Max/refs/heads/main/config_my/printer.cfg
wget --no-check-certificate https://raw.githubusercontent.com/Tombraider2006/Ender5Max/refs/heads/main/config_my/gcode_macro.cfg
wget --no-check-certificate https://raw.githubusercontent.com/Tombraider2006/Ender5Max/refs/heads/main/config_my/moonraker.conf

```

После этого перезагрузите принтер. или сервисы klipper и moonraker.
