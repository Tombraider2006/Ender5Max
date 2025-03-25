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


Что сделано:

1. перенесены некоторые параметры из gcode_macro в printer для упрощения логики.
2. убраны коментарии добавлены коментарии на русском.
3. убраны левые макросы
4. исправлены сущности
    * кулеры
    * светодиоды
    * непонятные пины
5. исправлены макросы кулера обдува.
6. исправлена логика включения подсветки при старте принтера и отображения в веб панели состояния подсветки.
7. добавлена сущность "Bed Warp Stabilisation" для дальнейшего использования в стартовом макросе для паузы перед сьемом карты стола после нагрева.
8. Добавлен `firmware retraction` как прописать его в слайсер [**смотри тут**](/firmware.md)
9. Добавлены и исправлены макросы `bedpid` `pid_hotend`
10.Добавлен  `wait_temp` макрос управляющий охлаждением после выключения нарева хотенда


Что не сделано:

1. макросы старта и окончания печати в том числе для установки модуля KAMP
2. не проверна возможность перевода принтера на sensorless homing
3. подключение датчика движения филамента (sfs)
