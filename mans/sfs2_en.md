# Installing SFS 2.0 Instead of Standard Filament Runout Sensor

## Why Upgrade?
Given the Ender 5 Max's large build volume, extended print times, and high filament consumption, basic runout detection alone is insufficient. The cost of filament jams can be exceptionally high, making a system that monitors both runout and movement an excellent solution.

This upgrade minimizes failure risks and prevents material/time losses.

## Wiring Options
Since standard sensors use 3 wires while SFS 2.0 uses 4, there are two installation methods:

### Method 1: Basic Replacement (No Additional Wiring)
Replaces only the movement detection functionality while maintaining the same wiring:

1. Repin the connector to 4-wire configuration:

## 2. Electrical Connection

| Sensor Cable | Ender 5 Max Connection |
|--------------|-----------------------|
| Red (+5V)    | 5V Power              |
| Black (GND)  | Ground                |
| Green (SIG)  | PC6 (Signal)         |
---------------------------------------

> **Note:** Verify polarity before connecting!


![](/images/sfs2_connector.jpg)

![](/images/sfs_pin.png)

in `printer.cfg` find and remove this

```
[filament_switch_sensor filament_sensor] 
switch_pin: !PC6
pause_on_runout: true
```

Add to `printer.cfg`:

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
### OR use with Optional audio alerts:

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
  # UPDATE_DELAYED_GCODE ID=sfs_alarm DURATION=1  # Uncomment for continuous alarms
```
## Method 2: Full Functionality (With Additional Wiring)
For complete sensor capabilities with reduced false positives:

1. Extend the 4th wire (blue) to motherboard:

Connect to available GPIO (PA15 shown)

![](/images/sfs_soldering.png)


Use proper wire extensions if needed

2. Update `printer.cfg` find and remove this

```
[filament_switch_sensor filament_sensor] 
switch_pin: !PC6
pause_on_runout: true
```

Add to `printer.cfg`:

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
# UPDATE_DELAYED_GCODE ID=sfs_alarm DURATION=1  # Uncomment for continuous alarms
```