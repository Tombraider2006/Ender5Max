
Немного, гы,  комментов к стандартным конфигам.


```
[tmc2209 extruder]
run_current: 0.6 #0.7
```


да.да. а я сижу и чето ржу.. снижая до 0.5 чтоб там не закисло все..

```
fade_start: 3.0#1
fade_end: 10
```
наконец таки... вместо 5-50...

```
# CR-10 SE
# Printer_size: 400x400x400 #220x220x265
```

чтоб вам подавиться

```
# Version: v1.2.10
# CreateDate: 2023/08/24
# Nozzle_mcu: chip: GD32F303CBT6
#             version: CR-NOZZLE_V21
# Leveling_mcu: chip: GD32E230F8P6
```

и теперь мы знаем на что жаловаться...

```
[hx711s]
count: 4
use_mcu: leveling_mcu
sensor0_clk_pin: leveling_mcu:PA2
sensor1_clk_pin: leveling_mcu:PA5
sensor2_clk_pin: leveling_mcu:PA6
sensor3_clk_pin: leveling_mcu:PA7
sensor0_sdo_pin: leveling_mcu:PA0
sensor1_sdo_pin: leveling_mcu:PA1
sensor2_sdo_pin: leveling_mcu:PA3
sensor3_sdo_pin: leveling_mcu:PA4
```


Вообще хз что это и новая фича от кралити..

```
[printer]
kinematics: corexy#cartesian
max_velocity: 1000 #600
max_accel: 100000 #8000
max_accel_to_decel: 5000
max_z_velocity: 30
square_corner_velocity: 5.0
max_z_accel: 300
```

я тут вообще хочу помолчать, но очень много мата в комментариях (мат в том числе что обновиться было бы неплохо до хотя бы апреля 2024 года) немного пояснений, с апреля 24 года вместо `max_accel_to_decel: 5000` пишется `minimum_cruise_ratio:` в переводе на русский: клиппер старый...

```
[stepper_z]
step_pin: PB6
dir_pin: PB5#!PB5
enable_pin: !PC3
microsteps: 32
rotation_distance: 3.9930 #3.985 #4 #8
gear_ratio: 1:1 #64:20
endstop_pin: tmc2209_stepper_z:virtual_endstop#PA15   #probe:z_virtual_endstop
position_endstop: 0
position_max: 406.5 #405 #400 #270
position_min: -5 #-5
```

в переводе на русский.. короче мы хер знает как это работает. вроде работает поэтому мы оставим это так...

```
#[output_pin aobi]
#pin: !nozzle_mcu: PB0
#[output_pin USB_EN]
#pin: !nozzle_mcu: PB0
```
я не знаю что это...


ребята.. даже не спрашиваете что это за часть конфига.. я в даже не знаю не то что бы рядом.. я вообще не знаю что это обозначает...

```
[resonance_tester]
accel_chip: adxl345
accel_per_hz: 50
probe_points: 200,200,5
#max_freq:90
```
да... , и к этой части конфига будут претензии..  во первых. вы сначала тестили на 75 герцах, потом на 90 потом закоментили... зачем?  зачем опустили до 50? нет, я знаю зачем до 50, потому что у вас 400 мм портал. но блин.. что за херня мать вашу присходит..


```
[heater_bed]
heater_pin: PA4 #PB2
sensor_type: EPCOS 100K B57560G104F
sensor_pin: PC4
#control = watermark
control = pid
pid_kp = 30    #37
pid_ki = 0.075 #0.10
pid_kd = 800   #1000
min_temp: -30
max_temp: 130
#temp_offset_flag = True

```
чисто поржать.. у вас зима наступила?

минимальная температура минус *блин* 30 градусов.. у меня 2 варианта.. или датчик **с ума сошел** или в вашей лаборатории окно открыли и вы в пустыне гоби..

```
#############FAN OLD CONFIG
[output_pin MainBoardFan]
```
без комментариев

```
[filter]
hft_hz: 1
lft_k1: 0.95
lft_k1_oft: 0.95
lft_k1_cal: 0.95

[dirzctl]
use_mcu: mcu
step_base: 2

#[output_pin aobi]
#pin: !nozzle_mcu: PB0
#[output_pin USB_EN]
#pin: !nozzle_mcu: PB0

```

что это????


ребята.. даже не спрашиваете что это за часть конфига.. я в даже не знаю не то что бы рядом.. я вообще не знаю что это обозначает...

вот изза таких непонятных параметров я и очкую переводить на стандартный клиппер.

я сильно не понимаю. что вы написали дальше ...

```

###YINZHI
[gcode_macro RED_LED_ON]
gcode:
  SET_PIN PIN=red_pin VALUE=1

[gcode_macro RED_LED_OFF]
gcode:
  SET_PIN PIN=red_pin VALUE=0

[gcode_macro GREEN_LED_ON]
gcode:
  SET_PIN PIN=green_pin VALUE=1

[gcode_macro GREEN_LED_OFF]
gcode:
  SET_PIN PIN=green_pin VALUE=0

[gcode_macro YELLOW_LED_ON]
gcode:
  SET_PIN PIN=yellow_pin VALUE=1

[gcode_macro YELLOW_LED_OFF]
gcode:
  SET_PIN PIN=yellow_pin VALUE=0

[gcode_macro LIGHT_LED_ON]
gcode:
  SET_PIN PIN=light_pin VALUE=1

[gcode_macro LIGHT_LED_OFF]
gcode:
  SET_PIN PIN=light_pin VALUE=0
```

```
[gcode_macro INPUTSHAPER]
gcode:
  #M84
  SET_FILAMENT_SENSOR SENSOR=filament_sensor ENABLE=0
  G90
  G28 X Y Z
  {% set POSITION_X = 200 %}
  {% set POSITION_Y = 200 %}
  G1 X{POSITION_X} Y{POSITION_Y} Z5 F6000
  #G4 P300 все что после "#" не читается.. следующие строки это дань прошлым прошивкам..
  #{% if 'X' in params.AXES|upper %}
  #  SHAPER_CALIBRATE AXIS=x
  #{% elif 'Y' in params.AXES|upper %}
  #  SHAPER_CALIBRATE AXIS=y
  #{% else %}
  SHAPER_CALIBRATE
  #{% endif %}
  CXSAVE_CONFIG
  SET_FILAMENT_SENSOR SENSOR=filament_sensor ENABLE=1
```


непереводимая игра слов местного диалекта.. экспрессия от длительного непонимания оппонентов... что не стоит делать только шейпер игрек.. закоментили.. нет это конечно не избавило от нехорошей привычки ограничить шейпер EI но хоть 'неопределенный артикль' что то...
