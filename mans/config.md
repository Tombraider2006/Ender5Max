<h2>Исправления конфигурации принтера для большей функциональности.</h2>

открываем printer.cfg

 1. найдем раздел  `[printer]`

```
[printer]
kinematics: corexy
max_velocity: 800
max_accel: 20000
max_accel_to_decel: 10000
max_z_velocity: 30
square_corner_velocity: 5.0
max_z_accel: 300

```
исправив его данным образом уйдем от неправильных значений максимальных ускорений изза которых при неправильных настройках слайсера мы можем повредить принтер.

 2. после этого раздела добавим строку:

```
[exclude_object]

```
Это добавит функционал исключения объектов, крайне востребованная функция для принтеров с таким размером рабочего стола.

 3. в разделе `[adxl345]` строка `axes_map: x,-z,y` точно неправильная, но пока не выяснил как записать правильно. 

 4. Лампочка состояния принтер, по отзывам, горит слишком ярко. Исправим это: ищем следующие разделы и меняем как написано тут. также исправляем логику подсветки стола которая была инвертирована.

 ```
[output_pin green_pin]
pin: PA0
pwm: True
cycle_time: 0.010
value: 0
[output_pin red_pin]
pin: PC1
pwm: True
cycle_time: 0.010
value: 0
[output_pin yellow_pin]
pin: PA1
pwm: True
cycle_time: 0.010
value: 0.01
[output_pin light_pin]
#pin: nozzle_mcu: PB0 #PA10
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0
 ```
чтобы алгоритмы отрабатывали правильно нам необзодимо также исправить файл `gcode_macro.cfg` заходим туда и находим следующие разделы и меняем их на представленные ниже

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
  SET_PIN PIN=green_pin VALUE=0.02

[gcode_macro GREEN_LED_OFF]
gcode:
  SET_PIN PIN=green_pin VALUE=0

[gcode_macro YELLOW_LED_ON]
gcode:
  SET_PIN PIN=_yellow_pin VALUE=0.01

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
красный я оставил без изменений чтобы чтобы при ошибке привлечь ваше внимание. однако вы можете поменять яркость и на нем. 

