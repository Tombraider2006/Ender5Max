## Установка датчика движения филамента вместо стандартного датчика окончания филамента

[**english version**](/mans/sfs2_en.md)

![](/images/sfs_1.png)

Учитывая большую область печати на этом принтере, значительное время печати и высокий расход филамента, контроля только за его окончанием явно недостаточно. Цена ошибки в случае застревания материала будет крайне высока, поэтому установка системы мониторинга не только окончания, но и застревания филамента — отличное решение.

Это позволит минимизировать риски сбоев и избежать потерь времени и материалов.

Так как в обычном датчике филамента у нас три провода, а в sfs 2.0 их 4 то есть два способа установки. 
* первый предполагает соединение только датчика движения вместо окончания филамента, что логично. если нет филамента то он и не движется, что все равно приведет к сработке.
* однако в конструкции нашего принтера не так уж и сложно подвести дополнительный провод, так что этот вариант мы тоже рассмотрим. 

## Первый способ

(замена датчика без дополнительной проводки)

Для этого нам нужно переставить провода в колодку на 4 провода. например так:

![](/images/sfs2_connector.jpg)

значения на коннекторе следующие:

![](/images/sfs_pin.png)


Далее заходим в `printer.cfg` и ищем строки:

```
[filament_switch_sensor filament_sensor] # датчик филамента
switch_pin: !PC6
pause_on_runout: true
```

и заменяем на:

```
[filament_motion_sensor filament_sensor]
detection_length: 5.3
extruder:extruder
pause_on_runout: true
switch_pin: ^PC6
runout_gcode:
  RESPOND TYPE=command MSG="Filament runout/blocked!"
insert_gcode:
  RESPOND TYPE=command MSG="Filament inserted"

```

**или** можем побаловаться с оповещением и при паузе прозвучит несколько звуковых сигналов

```
[gcode_shell_command beep]
command: beep
timeout: 2
verbose: False

[gcode_macro BEEP]
description: Play a sound
gcode:
  RUN_SHELL_COMMAND CMD=beep

[filament_motion_sensor encoder_sensor]
switch_pin: ^!PC6
detection_length: 5.3 # возможно сделать чуть меньше 2.7 по умолчанию
extruder: extruder
runout_gcode:
  RESPOND TYPE=command MSG="Filament runout/blocked!"
  UPDATE_DELAYED_GCODE ID=sfs_alarm DURATION=1
insert_gcode:
  RESPOND TYPE=command MSG="Filament inserted"
  UPDATE_DELAYED_GCODE ID=sfs_alarm DURATION=0


[delayed_gcode sfs_alarm]
# initial_duration: 0
gcode:
  beep
  beep
  beep
  beep
  beep
  beep
  #UPDATE_DELAYED_GCODE ID=sfs_alarm DURATION=1 #если убать комент в начале строки то сигналы будут постоянно.
```
## Второй способ

Если ваши руки не для скуки то можно получить полную функциональность датчика с меньшим количеством отказов для этого надо задействовать все 4 провода от датчика. 

Для начала, я соеденил конектор из комплекта через переходник(*дендрофекальным способом*)

![](/images/sfs_connector.png)

Оставшийся **синий** провод надо протянуть до нашей материнской платы и и припаять к этому выходу. На фото он красный потому что родного провода не хватает буквально 10 сантиметров и я его нарастил. 

![](/images/sfs_soldering.png)

заходим в `printer.cfg` и ищем строки:

```
[filament_switch_sensor filament_sensor] # датчик филамента
switch_pin: !PC6
pause_on_runout: true
```

и заменяем на:


```
[gcode_shell_command beep]
command: beep
timeout: 2
verbose: False

[gcode_macro BEEP]
description: Play a sound
gcode:
  RUN_SHELL_COMMAND CMD=beep

[filament_switch_sensor filament_sensor]
switch_pin: PA15
pause_on_runout: true
# runout_gcode: PAUSE



[filament_motion_sensor encoder_sensor]
switch_pin: ^!PC6
detection_length: 5.3
extruder: extruder
runout_gcode:
  RESPOND TYPE=command MSG="Filament runout/blocked!"
  UPDATE_DELAYED_GCODE ID=sfs_alarm DURATION=1
insert_gcode:
  RESPOND TYPE=command MSG="Filament inserted"
  UPDATE_DELAYED_GCODE ID=sfs_alarm DURATION=0


[delayed_gcode sfs_alarm]
# initial_duration: 0
gcode:
  beep
  beep
  beep
  beep
  beep
  beep
```