<h3 align="right"><a href="https://www.tinkoff.ru/rm/yakovleva.irina203/51ZSr71845" target="_blank">ваше "спасибо" автору</a></h3>
<h3 align="right"><a href="https://t.me/tombraider2006" target="_blank">телеграм канал автора</a></h3>

<h2>Прошивки</h2>


На данный момент получить  `root` можно с помощью прошивки [1.2.0.21](https://www.crealitycloud.com/downloads/firmware/ender-series/ender-5-max) с паролем `creality_2024`

![](/images/root1.jpg)

![](/images/root2.jpg)

![](/images/root3.jpg)





<details><summary>или с помощью модифицированной прошивки https://github.com/zevaryx/ender-5-max-firmware/releases/latest устарело</summary>

с паролем `creality_2025` 

Если просто залить на флешку установить в принтер и согласиться на обновление не получается и у вас стояла более ранняя прошивка с доступом `root` то можно попробовать заставить обновиться принудительно

```
/etc/ota_bin/local_ota_update.sh /tmp/udisk/sda/*.img
```

или


```
/etc/ota_bin/local_ota_update.sh /tmp/udisk/sda1/*.img
```
после обновления необходимо выключить\включить питание! обязательно!


## Вернуться к прошивке предыдущей 

Чтобы сбросить прошивку, установить более ранюю или вернутся на стоковую прошивку

по ssh заходим и вставляем следующие команды:

```
# Получить текущую версию, независимо от того, какая она
VERSION=$(grep 'ota_version' '/etc/ota_info' | awk -F'=' '{print $2}')

# Принудительно установить версию 1.0.0.0, что ниже минимума
for file in /etc/ota_info /usr/data/creality/userdata/config/system_version.json; do
    sed -i -e "s/${VERSION}/1.0.0.0/g" $file
done

# Перезагрузить систему для принудительной перезагрузки файлов с диска
reboot
```
После этого можно подсунуть системе любую прошивку, она воспримет ее как новую.
</details>
## Установка HELPER-SCRIPT

### Внимание! если вы установите хелпер скрипт то отключите уведомление об обновлении. так же не обновляйте потом прошивку по wifi пока не сбросите принтер до заводских настроек. 


*21.05.2025 -Внимание.*

*Guilois, автор helper script, наконец то обратил внимание на данный принтер и выделил, наконец, ветку под него, но дальнейшего развития не получил, поэтому ставить надо только те пункты которые подойдут нашему принтеру, слепо ставить все подряд нельзя, иначе принтер уйдет в ошибку или перестанет нормально функционировать. 

Пока не приехал ваш картографер, а печатать уже хочется можно облегчить себе жизнь установкой привычной оболочки klipper. Для этого необходимо установить [**хелпер скрипт**](https://guilouz.github.io/Creality-Helper-Script-Wiki/helper-script/helper-script-installation/) и получить базовую функциональность клиппера.



для этого через ssh нам необходимо ввести следующие команды:

```
git clone --depth 1 https://github.com/Guilouz/Creality-Helper-Script.git /usr/data/helper-script
```
после того как скрипт скачается запускаем его

```
sh /usr/data/helper-script/helper.sh
```

пункт 1 install


![](/images/helper_script.jpg)

рекомендуемые пункты меню 1, 2, 4, 5, 10. если у вас есть видеокамера то 16.



Лучше сверяйтесь в [**Группе пользователей принтера в телеграм**](https://t.me/Ender_5_Max_Ru) по правильности пунктов. бывает  что могут смениться без предупреждения.


через  браузер теперь мы можем зайти на наш принтер в расширенную вебпанель с доступом к файлам конфигурации и расширенным настройкам. Не забываем указать порт `http://Ваш_ip:4408` если вы установили Fluid и `http://Ваш_ip:4409`  если Mainsail

## После установки

немного оживим наш конфиг:

в вебпанели ищем значок слева {...}  в окошке ищем файл `gcode_macro.cfg` открываем его и мотаем в самый низ

добавим следующий код:

```
[firmware_retraction]
retract_length: 0.45 # безопасное значение для того пластика которым чаще всего печатаете.
retract_speed: 30
unretract_extra_length: 0
unretract_speed: 30

[gcode_shell_command beep]
command: beep
timeout: 2
verbose: False

[gcode_macro BEEP] # звук бип. 
description: Play a sound
gcode:
  RUN_SHELL_COMMAND CMD=beep

[delayed_gcode light_init] 
initial_duration: 5.01
gcode:
  SET_PIN PIN=light_pin VALUE=1

[exclude_object] # исключение обьектов. 


[gcode_macro PID_BED]
gcode:
  PID_CALIBRATE HEATER=heater_bed TARGET={params.BED_TEMP|default(70)}
  SAVE_CONFIG

[gcode_macro PID_HOTEND] # и почему его не было. добавил
description: Start Hotend PID
gcode:
  G90
  G28
  G1 Z10 F600
  M106 S255 #S255 
  PID_CALIBRATE HEATER=extruder TARGET={params.HOTEND_TEMP|default(250)}
  M107

```

сохраняем. 

теперь задачка посложнее. открываем файл `printer.cfg`

ищем параметр `[output_pin Height_module2]` и меняем его на 

```
[output_pin _Height_module2]
```

ищем раздел:

```diff
[output_pin light_pin]
#pin: nozzle_mcu: PB0 #PA10
pin: PC0
value: 0.0
```
меняем на 

```
[output_pin light_pin] #  освещение камеры принтера. косяк прошивки креалити.
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0
```

чтобы принтер не шумел обдувом материнской платы при простое. надо заменить раздел

```
[output_pin MainBoardFan]
pin: !PB1
```

меняем на:

```
[controller_fan MCU_fan] # включаем обдув после включения драйверов
pin: PB1
max_power: 1.0
fan_speed: 1
kick_start_time: 0
stepper: stepper_x

```


Чтобы подготовить принтер к работе пройдем тесты и запишем их в конфиг, сделать это проще чем кажется. Для этого достаточно скопировать код в консоль вебпанели принтера. тесты будут длится около 10-20 минут, после этого принтер перезагрузится и будет готов к работе.

```
PID_BED
PID_HOTEND
INPUT_SHAPER_CALIBRATION
```

## OrcaSlicer
В слайсере орка начиная с 2.3.0 есть готовый профиль под принтер Ender 5 max 

но можно и там найти пару косяков и исправить.

в стартовом коде добавить:

```
M140 S0
M104 S0
```
вот так

![](/images/orca11.jpg)


**В разделе экструдер** искренно советую понизить скорость ретракта до 30 мм\мсек вместо 50 по умолчанию в 2 местах.

это сохранит шестерни фидера от преждевременного износа.

## Использовать ретракт из прошивки

1. правим стартовый код, добавляем этот блок так:

![](/images/start_code.png)

```
SET_RETRACTION RETRACT_LENGTH=[retraction_length] RETRACT_SPEED=[retraction_speed] UNRETRACT_EXTRA_LENGTH=[retract_restart_extra] UNRETRACT_SPEED=[deretraction_speed]
RESPOND TYPE=command MSG="Retraction length set to [retraction_length]mm" 
RESPOND TYPE=command MSG="Retract speed set to [retraction_speed]/[deretraction_speed]mm/c"

```

2. поставим галку тут

![](/images/orca1.png)

3. потом убираем галку тут

![](/images/orca2.png)

4. не забываем указывать в пластике указывать откат настроенный.

![](/images/orca3.jpg)




## Посмотреть стоковые файлы конфигурации 

1.2.0.10 [тут](/stock/config_1.2.0.10/)

1.2.0.20 [тут](/stock/config_1.2.0.20/)

1.2.0.21 [тут](/stock/config_1.2.0.21/)





На данный момент (август 2025) одна из самых допиленных версий прошивок это от pelkorp с его [**SimpleAF**](https://pellcorp.github.io/creality-wiki/).  К ее недостаткам можно отнести только что поставить можно **!!!только** на картографер и бекон. связано это с тем что не смогли подружить с новым клиппером плату головы а точнее акселерометр. так как в картографере и беконе внутри плат есть акселерометры свои, вышли из положения таким образом.  

Вполне возможно что через некоторое время ситуация измениться.  

Если вы захотите использовать guppyscreen в SimpleAF то необходимо [повернуть экран на 90 градусов.](https://github.com/Tombraider2006/Ender5Max/blob/main/mans/simpleaf.md#%D0%B2%D1%8B-%D0%BA%D1%83%D0%BF%D0%B8%D0%BB%D0%B8-%D0%B7%D0%B0%D1%88%D0%B8%D0%B2%D0%BA%D1%83-%D0%BA%D0%BE%D1%80%D0%BF%D1%83%D1%81%D0%B0-%D0%B8-%D1%82%D0%B5%D0%BF%D0%B5%D1%80%D1%8C-%D0%BF%D1%80%D0%BE%D0%B2%D0%BE%D0%B4%D0%B0-%D0%BC%D0%B5%D1%88%D0%B0%D1%8E%D1%82-%D0%BE%D1%82%D0%BA%D1%80%D1%8B%D0%B2%D0%B0%D1%82%D1%8C-%D0%B4%D0%B2%D0%B5%D1%80%D1%86%D1%83) вот [**модель**](/mans/Ender5MaxTiltedScreenMount.stl) чтобы закрепить экран в горизонтальном положении. 

### Если получаем ошибку 2069

В файле `printer.cfg` находим разделы и удаляем.

```diff
###喷头前面风扇
[output_pin fan0]
pin: !nozzle_mcu:PB15
pwm: True
cycle_time: 0.01
hardware_pwm: false
value: 0.00
scale: 255
shutdown_value: 0.0
[output_pin en_fan0]
pin: nozzle_mcu: PB6
pwm: False
value: 1.0

###喷头后面风扇
[output_pin fan1]
pin: !nozzle_mcu:PA9
pwm: True
cycle_time: 0.01
hardware_pwm: false
value: 0.00
scale: 255
shutdown_value: 0.0
[output_pin en_fan1]
pin: nozzle_mcu: PB9
pwm: False
value: 1.0

```
заменяем на:

```

[multi_pin part_fans]
pins:!nozzle_mcu:PB15,!nozzle_mcu:PA9

[multi_pin en_part_fans]
pins:nozzle_mcu:PB6,nozzle_mcu:PB9

[fan_generic part]
pin: multi_pin:part_fans
enable_pin: multi_pin:en_part_fans
cycle_time: 0.0100
hardware_pwm: false
```

в файле `gcode_macro.cfg` ищем разделы и удаляем:


```diff
[gcode_macro M106]
gcode:
  {% set fan = 0 %}
  {% set value = 255 %}
  {% if params.S is defined %}
    {% set tmp = params.S|int %}
    {% if tmp <= 255 %}
      {% set value = tmp %}
    {% endif %}
  {% endif %}
  {% if params.P is defined %}
    {% set value = (255 - printer["gcode_macro PRINTER_PARAM"].fan1_min) / 255 * tmp %}
    {% set value = printer["gcode_macro PRINTER_PARAM"].fan1_min + value %}
    {% if value >= 255 %}
      {% set value = 255 %}
    {% endif %}
    SET_PIN PIN=fan1 VALUE={value}

    {% set value = (255 - printer["gcode_macro PRINTER_PARAM"].fan0_min) / 255 * tmp %}
    {% set value = printer["gcode_macro PRINTER_PARAM"].fan0_min + value %}
    {% if value >= 255 %}
      {% set value = 255 %}
    {% endif %}
    SET_PIN PIN=fan0 VALUE={value}
  {% else %}
    {% set value = (255 - printer["gcode_macro PRINTER_PARAM"].fan1_min) / 255 * tmp %}
    {% set value = printer["gcode_macro PRINTER_PARAM"].fan1_min + value %}
    {% if value >= 255 %}
      {% set value = 255 %}
    {% endif %}
    SET_PIN PIN=fan1 VALUE={value}

    {% set value = (255 - printer["gcode_macro PRINTER_PARAM"].fan0_min) / 255 * tmp %}
    {% set value = printer["gcode_macro PRINTER_PARAM"].fan0_min + value %}
    {% if value >= 255 %}
      {% set value = 255 %}
    {% endif %}
    SET_PIN PIN=fan0 VALUE={value}

  {% endif %}
  {% if tmp < 1 %}
    {% set value = tmp %}
    SET_PIN PIN=fan0 VALUE={value}
    SET_PIN PIN=fan1 VALUE={value}
  {% endif %}


[gcode_macro M107]
gcode:
  {% if params.P is defined %}
    SET_PIN PIN=fan0 VALUE=0
    SET_PIN PIN=fan1 VALUE=0
  {% else %}
    SET_PIN PIN=fan0 VALUE=0
    SET_PIN PIN=fan1 VALUE=0
  {% endif %}

```
заменяем на:

```
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

```
в самом верху файла ищем  и удаляем строки

```
variable_fan0_min: 90 #240 #90
variable_fan1_min: 70 #240 #70
```
