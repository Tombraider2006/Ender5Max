#!/bin/bash

show_menu() {
    clear
    printf "========================================\n"
    printf "🚀 Tom Tomich Script (Ender-5 Max Fix)\n"
    printf "\033[1;34;5;1mВНИМАНИЕ! Вносить изменения только после установки Helper Script пунктов 1,(2 и\или 3),4,5,10\033[0m\n"
    printf "========================================\n"

    if [ -f "/usr/data/printer_data/config/gcode_macro.cfg.bak" ] || [ -f "/usr/data/printer_data/config/printer.cfg.bak" ]; then
        printf "[1] \033[1;31mИсправления уже установлены\033[0m\n"
        printf "[2] \033[1;32mОткатить исправления\033[0m\n"
    else
        printf "[1] \033[1;32mУстановить исправления\033[0m\n"
        printf "[2] \033[1;31mОткат невозможен\033[0m\n"
    fi
    printf "[3] Выйти\n"
}

install_fix() {
    if [ -f "/usr/data/printer_data/config/gcode_macro.cfg.bak" ] || [ -f "/usr/data/printer_data/config/printer.cfg.bak" ]; then
        echo "Исправления уже установлены."
        return
    fi

    cp /usr/data/printer_data/config/gcode_macro.cfg /usr/data/printer_data/config/gcode_macro.cfg.bak
    cp /usr/data/printer_data/config/printer.cfg /usr/data/printer_data/config/printer.cfg.bak

    cat > /usr/data/printer_data/config/gcode_macro.cfg <<'EOF'
# CR-10 SE
# [gcode_macro G29]
# gcode:
#     NOZZLE_CLEAR
#     M106 S0
#     BED_MESH_CALIBRATE
#     CXSAVE_CONFIG

[gcode_macro PRINTER_PARAM]
variable_z_safe_pause: 0.0
variable_z_safe_g28: 3.0
variable_max_x_position: 400 #220.0
variable_max_y_position: 400 #220.0
variable_max_z_position: 400 #250.0
variable_fans: 3
variable_auto_g29: 0
variable_default_bed_temp: 45
variable_default_extruder_temp: 140 #240
variable_g28_extruder_temp: 140
variable_g28_ext_temp: 140
variable_print_calibration: 0
variable_fan0_min: 90 #240 #90
variable_fan1_min: 70 #240 #70
variable_extruder_save_temp: 0
gcode:

[gcode_macro STRUCTURE_PARAM]
variable_bed_length: 400 #220
variable_bed_width: 400 #220
variable_bed_hight: 400 #250
variable_laser_x_offset: 45.0
variable_laser_y_offset: -8.0
variable_laser_z_offset: 3.0
variable_cali_x_offset: 200.9
variable_cali_y_offset: 8.9
variable_cali_z_offset: 5.0
gcode:

[virtual_sdcard]
#path: /home/rock/gcode_files
path: /usr/data/printer_data/gcodes

[pause_resume]

[display_status]
[gcode_macro CANCEL_PRINT]
description: Cancel the actual running print
rename_existing: CANCEL_PRINT_BASE
gcode:
    #G91
    #G1 Z50

    #G91
    #{% set cur_remain = (406.0 - printer.toolhead.position.z)|float %}
    #{action_respond_info("====cxzz11=====CANCEL_PRINT====position.z:%f====cur_remain:%f====\n" % ( printer.toolhead.position.z, cur_remain))}
    #{% if (cur_remain > 0) %}
    #  {% if (cur_remain < 50) %}
    #    {action_respond_info("========1111111====zz==== \n")}
    #    {% set z_safe = cur_remain %}
    #  {% else %}
    #    {action_respond_info("========2222222====zz==== \n")}
    #    {% set z_safe = 50 %}
    #  {% endif %}
    #{% else %}
    #  {% set z_safe = 0.1 %}
    #{% endif %}
    #G1 Z{z_safe} F300

    G90
    {% set cur_remain = (380.0 - printer.toolhead.position.z)|float %}
    {action_respond_info("========CANCEL_PRINT====cur_remain:%f========\n" % ( cur_remain ))}
    {% if (cur_remain > 0) %}
      G1 Z380 F300
    #{% elif printer.toolhead.position.z < 406.0 %}
      #G1 Z406 F300
    {% else %}
      {action_respond_info("========CANCEL_PRINT====zz==== \n")}
    {% endif %}


    G90
    G1 F3000X400Y400
    M104 S0
    M140 S0
    M107
    M84
    TURN_OFF_HEATERS
    CANCEL_PRINT_BASE
    FINISH_INIT


[gcode_macro PRINT_CALIBRATION_EXT]
# This part of the command is replaced by the application side without passing parameters
gcode:
  #CX_PRINT_LEVELING_CALIBRATION
  {% if 'PROBE_COUNT' in params|upper %}
    {% set get_count = ('PROBE_COUNT' + params.PROBE_COUNT) %}
  {%else %}
    {% set get_count = "" %}
  {% endif %}

  {% set bed_temp = printer.custom_macro.default_bed_temp %}
  {% set extruder_temp = printer.custom_macro.g28_ext_temp %}
  {% set nozzle_clear_temp = printer.custom_macro.default_extruder_temp %}

  {% if 'BED_TEMP' in params|upper %}
    {% set bed_temp = params.BED_TEMP %}
  {% endif %}

  {% if 'EXTRUDER_TEMP' in params|upper %}
    #{% set nozzle_clear_temp = params.EXTRUDER_TEMP %}
    {% set nozzle_clear_temp = 200 %}
  {% endif %}

  G28
  BED_MESH_CLEAR
  NOZZLE_CLEAR HOT_MIN_TEMP={extruder_temp} HOT_MAX_TEMP={nozzle_clear_temp} BED_MAX_TEMP={bed_temp}
  ACCURATE_G28
  M204 S5000
  SET_VELOCITY_LIMIT ACCEL_TO_DECEL=5000
  BED_MESH_CALIBRATE {get_count}
  BED_MESH_OUTPUT
  #{% set y_park = printer.toolhead.axis_maximum.y/2 %}
  #{% set x_park = printer.toolhead.axis_maximum.x|float - 10.0 %}
  {% set y_park = 400 %}
  {% set x_park = 400 %}
  #G1 X{x_park} Y{y_park} F2000
  CXSAVE_CONFIG
  TURN_OFF_HEATERS


[gcode_macro FIRST_FLOOR_PAUSE_POSITION]
gcode:
  {% set extruder_temp = printer.custom_macro.g28_ext_temp %}
  M104 S{extruder_temp}
  #{% set y_park = printer.toolhead.axis_maximum.y/2 %}
  #{% set x_park = printer['gcode_macro PRINTER_PARAM'].max_x_position|float + 1 %}
  {% set y_park = 400 %}
  {% set x_park = 400 %}
  G90
  G1 Z2 F600
  G1 X{x_park} Y{y_park} F6000
  G1 Z0.2 F600

[gcode_macro FIRST_FLOOR_RESUME]
description: Resume the first floor print
gcode:
    ##### read E from pause macro #####
  {% set E = printer["gcode_macro FIRST_FLOOR_PAUSE"].extrude|float + 1.0 %}
  #### get VELOCITY parameter if specified ####
  {% if 'VELOCITY' in params|upper %}
    {% set get_params = ('VELOCITY=' + params.VELOCITY) %}
  {%else %}
    {% set get_params = "" %}
  {% endif %}
  ##### end of definitions #####
  {% if printer.extruder.can_extrude|lower == 'true' %}
    G91
    G1 E{E} F2100
  {% else %}
    {action_respond_info("Extruder not hot enough")}
  {% endif %}
  RESUME_BASE {get_params}

[gcode_macro FIRST_FLOOR_PAUSE]
description: Pause the first floor print
# change this if you need more or less extrusion
variable_extrude: 2.0
gcode:
  ##### read E from pause macro #####
  {% set E = printer["gcode_macro FIRST_FLOOR_PAUSE"].extrude|float %}
  ##### set park positon for x and y #####
  # default is your max posion from your printer.cfg

  #{% set y_park = printer.toolhead.axis_maximum.y/2 %}
  #{% set x_park = printer.toolhead.axis_maximum.x|float - 10.0 %}
  {% set y_park = 400 %}
  {% set x_park = 400 %}  
  ##### calculate save lift position #####
  {% set max_z = printer["gcode_macro PRINTER_PARAM"].max_z_position|float %}
  {% set act_z = printer.toolhead.position.z|float %}
  {% set z_safe = 0.0 %}
  {% if act_z < (max_z - 2.0) %}
    {% set z_safe = 2.0 %}
  {% elif act_z < max_z %}
    {% set z_safe = max_z - act_z %}
  {% endif %}
  ##### end of definitions #####
  SET_GCODE_VARIABLE MACRO=PRINTER_PARAM VARIABLE=z_safe_pause VALUE={z_safe|float}
  PAUSE_BASE
  G91
  {% if "xyz" in printer.toolhead.homed_axes %}
    {% if printer.extruder.can_extrude|lower == 'true' %}
      G1 E-1.0 F180
      G1 E-{E} F4000
    {% else %}
      {action_respond_info("Extruder not hot enough")}
    {% endif %}
    G1 Z{z_safe} F600
    G90
    G1 X{x_park} Y{y_park} F30000
  {% else %}
    {action_respond_info("Printer not homed")}
  {% endif %}
  # save fan2 value and turn off fan2
  SET_GCODE_VARIABLE MACRO=PRINTER_PARAM VARIABLE=fan2_speed VALUE={printer['output_pin fan2'].value}
  {% set fspeed = printer['gcode_macro PRINTER_PARAM'].fan2_speed %}
  {action_respond_info("fan2_value = %s \n" % (fspeed))}
  # SET_PIN PIN=fan2 VALUE=0
  #M106 P2 S0

[gcode_macro PAUSE]
description: Pause the actual running print
rename_existing: PAUSE_BASE
# change this if you need more or less extrusion
variable_extrude: 1.0
gcode:
    ##### read E from pause macro #####
    {% set E = printer["gcode_macro PAUSE"].extrude|float %}
    ##### set park positon for x and y #####
    # default is your max posion from your printer.cfg
    # {% set x_park = printer.toolhead.axis_maximum.x|float - 5.0 %}
    # {% set y_park = printer.toolhead.axis_maximum.y|float - 5.0 %}
    RED_LED_OFF
    GREEN_LED_OFF
    YELLOW_LED_ON
    #{% set x_park = 400 %}
    #{% set y_park = 400 %}
    {% set x_park = 0 %}
    {% set y_park = 0 %}
    ##### calculate save lift position #####
    {% set max_z = printer.toolhead.axis_maximum.z|float %}
    {% set act_z = printer.toolhead.position.z|float %}
    {action_respond_info("====cxzz11=====act_z:%f====max_z:%f====\n" % ( act_z, max_z))}
    #{% if act_z < 48.0 %}
    #    {% set z_safe = 50.0 - act_z %}
    #{% elif act_z < (max_z - 2.0) %}
    #    {% set z_safe = 2.0 %}
    #{% else %}
    #    {% set z_safe = max_z - act_z %}
    #{% endif %}
    {% set cur_remain = (406.0 - printer.toolhead.position.z)|float %}
    {action_respond_info("====cxzz11=====PAUSE====position.z:%f====cur_remain:%f====\n" % ( printer.toolhead.position.z, cur_remain))}
    {% if (cur_remain > 0) %}
      {% if (cur_remain < 50) %}
        {action_respond_info("========1111111====zz==== \n")}
        {% set z_safe = cur_remain %}
      {% else %}
        {action_respond_info("========2222222====zz==== \n")}
        {% set z_safe = 50 %}
      {% endif %}
    {% else %}
      {% set z_safe = 0.1 %}
    {% endif %}

    SET_GCODE_VARIABLE MACRO=PRINTER_PARAM VARIABLE=z_safe_pause VALUE={z_safe|float}
    ##### end of definitions #####
    PAUSE_BASE
    G91
    {% if printer.extruder.can_extrude|lower == 'true' %}
      G1 E-{E} F2100
    {% else %}
      {action_respond_info("Extruder not hot enough")}
    {% endif %}
    {% if "xyz" in printer.toolhead.homed_axes %}
      G1 Z{z_safe} F300
      G90
      G1 X{x_park} Y{y_park} F6000
      M400

      #yinzhi
      #{action_respond_info("---------yyyinzhi pause print callback----vvvvvvvvvv1122---- \n")}
      {% set cur_temp = printer.extruder.temperature %}
      SET_GCODE_VARIABLE MACRO=PRINTER_PARAM VARIABLE=extruder_save_temp VALUE={cur_temp|int}
      M104 S140
      #M140 S60
      #M107
    {% else %}
      {action_respond_info("Printer not homed")}
    {% endif %} 
    
[gcode_macro RESUME]
description: Resume the actual running print
rename_existing: RESUME_BASE
gcode:
    ##### read E from pause macro #####
    {% set E = printer["gcode_macro PAUSE"].extrude|float %}
    #### get VELOCITY parameter if specified ####
    {% if 'VELOCITY' in params|upper %}
      {% set get_params = ('VELOCITY=' + params.VELOCITY)  %}
    {%else %}
      {% set get_params = "" %}
    {% endif %}
    {% set z_resume_move = printer['gcode_macro PRINTER_PARAM'].z_safe_pause|int %}
    {% if z_resume_move > 2 %}
      {% set z_resume_move = z_resume_move - 2 %}
      G91
      G1 Z-{z_resume_move} F600
      M400
    {% endif %}

    ##### end of definitions #####
    {% if printer.extruder.can_extrude|lower == 'true' %}
      G91
      G1 E{E} F2100
    {% else %}
      {action_respond_info("Extruder not hot enough")}
    {% endif %}  
    RESUME_BASE {get_params}
    RED_LED_OFF
    GREEN_LED_ON
    YELLOW_LED_OFF


[gcode_macro M900]
gcode:
  {% if 'K' in params %}
    {% if 'E' in params %}
      SET_PRESSURE_ADVANCE EXTRUDER={params.E} ADVANCE={params.K}
    {% else %}
      SET_PRESSURE_ADVANCE ADVANCE={params.K}
    {% endif %}
  {% endif %}


[gcode_arcs]#打印圆
resolution: 1.0


[gcode_macro M204]
rename_existing: M204.1
gcode:
  # {% if printer['gcode_macro Qmode'].flag|int == 0 %}
  {% set get_params = "" %}
  {% if 'S' in params|upper %}
    {% set get_params = (get_params + ' ' + 'S' + params.S) %}
  {% endif %}
  {% if 'P' in params|upper %}
    {% set get_params = (get_params + ' ' + 'P' + params.P) %}
  {% endif %}
  {% if 'T' in params|upper %}
    {% set get_params = (get_params + ' ' + 'T' + params.T) %}
  {% endif %}
  M204.1 {get_params}
  # {% endif %}


[gcode_macro M205]
gcode:
  {% if 'X' in params %}
    SET_VELOCITY_LIMIT SQUARE_CORNER_VELOCITY={params.X}
  {% elif 'Y' in params %}
    SET_VELOCITY_LIMIT SQUARE_CORNER_VELOCITY={params.Y}
  {% endif %}


[gcode_macro ACCURATE_G28]
gcode:
  G28 Z

#[gcode_macro G29]
#gcode:
#  M204 S5000
#  G90
#  G28
#  Z_OFFSET_AUTO
#  M104S0
#  M107
#  G28 Z
#  BED_MESH_CALIBRATE
#  G1 X200Y200Z10
#  M140S0
#  CXSAVE_CONFIG
[gcode_macro G29]
gcode:
  {% if 'PROBE_COUNT' in params|upper %}
    {% set get_count = ('PROBE_COUNT' + params.PROBE_COUNT) %}
  {%else %}
    {% set get_count = "" %}
  {% endif %}

  {% set bed_temp = printer.custom_macro.default_bed_temp %}
  {% set extruder_temp = printer.custom_macro.g28_ext_temp %}
  {% set nozzle_clear_temp = printer.custom_macro.default_extruder_temp %}

  {% if 'BED_TEMP' in params|upper %}
    {% set bed_temp = params.BED_TEMP %}
  {% endif %}

  {% if 'EXTRUDER_TEMP' in params|upper %}
    {% set nozzle_clear_temp = params.EXTRUDER_TEMP %}
  {% endif %}

  G28
  BED_MESH_CLEAR
  NOZZLE_CLEAR HOT_MIN_TEMP={extruder_temp} HOT_MAX_TEMP={nozzle_clear_temp} BED_MAX_TEMP={bed_temp}
  ACCURATE_G28
  M204 S5000
  SET_VELOCITY_LIMIT ACCEL_TO_DECEL=5000
  BED_MESH_CALIBRATE {get_count}
  BED_MESH_OUTPUT
  #{% set y_park = printer.toolhead.axis_maximum.y/2 %}
  #{% set x_park = printer.toolhead.axis_maximum.x|float - 10.0 %}
  #{% set y_park = 400 %}
  #{% set x_park = 400 %}
  {% set y_park = 200 %}
  {% set x_park = 200 %}
  G1 X{x_park} Y{y_park} F2000
  CXSAVE_CONFIG
  TURN_OFF_HEATERS


[gcode_macro Z_OFFSET_TEST]
gcode:
  # Z_OFFSET_AUTO
  G28
  # NOZZLE_CLEAR
  Z_OFFSET_CALIBRATION
  CXSAVE_CONFIG 


[gcode_macro ZZ_OFFSET_TEST]
gcode:
  G28
  Z_OFFSET_AUTO
  # NOZZLE_CLEAR
  # Z_OFFSET_CALIBRATION
  CXSAVE_CONFIG 


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

[gcode_macro LOAD_MATERIAL]
gcode:
  SAVE_GCODE_STATE NAME=myMoveState
  M109 S{printer.custom_macro.default_extruder_temp}
  G91
  G1 E150 F180
  RESTORE_GCODE_STATE NAME=myMoveState

[gcode_macro QUIT_MATERIAL]
gcode:
  #SAVE_GCODE_STATE NAME=myMoveState
  #M109 S{printer.custom_macro.default_extruder_temp}
  #G91
  #G1 E20 F180
  #G1 E-30 F180
  #G1 E-50 F2000
  #RESTORE_GCODE_STATE NAME=myMoveState

  SAVE_GCODE_STATE NAME=myMoveState
  M109 S{printer.custom_macro.default_extruder_temp}
  G91
  G1 E100 F300
  G1 E-15 F3000
  G1 E-22.4700 F2400
  G1 E-6.4200 F1200
  G1 E-3.2100 F720
  G1 E5.0000 F356
  G1 E-5.0000 F384
  G1 E5.0000 F412
  G1 E-5.0000 F440
  G1 E5.0000 F467
  G1 E-5.0000 F495
  G1 E5.0000 F523
  G1 E-5.0000 F3000
  G1 E-15 F3000
  RESTORE_GCODE_STATE NAME=myMoveState


[gcode_macro M600]
gcode:
  PAUSE
  {% set act_e = printer.toolhead.position.e|float %}
  G91
  G1 E20 F180
  G1 E-30 F180
  G1 E-50 F2000
  G90
  G92 E{act_e}


[gcode_macro FINISH_INIT]
gcode:
  M204 S5000
  SET_PRESSURE_ADVANCE ADVANCE=0.04


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


[gcode_macro INPUTSHAPER]
gcode:
  #M84
  SET_FILAMENT_SENSOR SENSOR=filament_sensor ENABLE=0
  G90
  G28 X Y Z
  {% set POSITION_X = 200 %}
  {% set POSITION_Y = 200 %}
  G1 X{POSITION_X} Y{POSITION_Y} Z5 F6000
  #G4 P300
  #{% if 'X' in params.AXES|upper %}
  #  SHAPER_CALIBRATE AXIS=x
  #{% elif 'Y' in params.AXES|upper %}
  #  SHAPER_CALIBRATE AXIS=y
  #{% else %}
  SHAPER_CALIBRATE
  #{% endif %}
  CXSAVE_CONFIG
  SET_FILAMENT_SENSOR SENSOR=filament_sensor ENABLE=1

[gcode_macro AUTOTUNE_SHAPERS]
variable_autotune_shapers: 'ei'
gcode:

[gcode_macro TUNOFFINPUTSHAPER]
gcode:
  SET_INPUT_SHAPER SHAPER_FREQ_X=0 SHAPER_FREQ_Y=0

[gcode_macro BEDPID]
gcode:
  PID_CALIBRATE HEATER=heater_bed TARGET=100
  SAVE_CONFIG

[gcode_macro PRINT_FINI_ZDN]
gcode:
  #{% set cur_remain = (406.0 - printer.toolhead.position.z)|float %}
  #{action_respond_info("====cxzz11=====PRINT_FINI_ZDN====position.z:%f====cur_remain:%f====\n" % ( printer.toolhead.position.z, cur_remain))}
  #{% if (cur_remain > 0) %}
  #  {% if (cur_remain < 50) %}
  #    {action_respond_info("========1111111====zz==== \n")}
  #    FORCE_MOVE STEPPER=stepper_z DISTANCE={cur_remain} VELOCITY=10
  #  {% else %}
  #    {action_respond_info("========2222222====zz==== \n")}
  #    FORCE_MOVE STEPPER=stepper_z DISTANCE=50 VELOCITY=10
  #  {% endif %}
  #{% endif %}

  {% set cur_remain = (380.0 - printer.toolhead.position.z)|float %}
  {action_respond_info("========PRINT_FINI_ZDN====cur_remain:%f========\n" % ( cur_remain ))}
  {% if (cur_remain > 0) %}
	FORCE_MOVE STEPPER=stepper_z DISTANCE={cur_remain} VELOCITY=10
  {% else %}
    {action_respond_info("========PRINT_FINI_ZDN====zz==== \n")}
  {% endif %}


EOF

cat > /usr/data/printer_data/config/printer.cfg <<'EOF'
# CR-10 SE
# Printer_size: 400x400x400 #220x220x265
# Version: v1.2.10
# CreateDate: 2023/08/24
# Nozzle_mcu: chip: GD32F303CBT6
#             version: CR-NOZZLE_V21
# Leveling_mcu: chip: GD32E230F8P6
#             version: CR-K1-MAX-LEVELING-V1.0.0
# mcu: chip: GD32F303RET6
#      version: CR4NS200323C10
[include sensorless.cfg]
[include gcode_macro.cfg]
[include printer_params.cfg]


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

[mcu]
serial:/dev/ttyS1
baud:230400
restart_method: command

[force_move]
enable_force_move: True
[mcu nozzle_mcu]
serial:/dev/ttyS7
baud: 230400
restart_method: command

[mcu leveling_mcu]
serial: /dev/ttyS6
baud: 230400
restart_method: command

[verify_heater extruder]
[verify_heater heater_bed]
check_gain_time: 120
heating_gain: 1.0
hysteresis: 10

[mcu rpi]
serial: /tmp/klipper_host_mcu

[bl24c16f]
i2c_mcu: rpi
i2c_bus: i2c.2
i2c_speed: 400000

[prtouch_v2]
z_offset: 0
step_base:2
pres_cnt: 4
show_msg: False
tilt_corr_dis: 0.00 #0.03
tri_min_hold: 8000 #12000 #4000 #1600
tri_max_hold: 16000 #26000 #8000 #6000
pres0_clk_pins: leveling_mcu:PA2
pres0_sdo_pins: leveling_mcu:PA0
pres1_clk_pins: leveling_mcu:PA5
pres1_sdo_pins: leveling_mcu:PA1
pres2_clk_pins: leveling_mcu:PA6
pres2_sdo_pins: leveling_mcu:PA3
pres3_clk_pins: leveling_mcu:PA7
pres3_sdo_pins: leveling_mcu:PA4
step_swap_pin: mcu:PA8 #PC10
pres_swap_pin: leveling_mcu:PB1 ##sync signal
speed: 3 #3#1.5
g28_wait_cool_down: true
noz_ex_com: 0.085 #0.082 #0.085 #0 #0.2
pa_clr_down_mm: -0.05
rdy_xy_spd: 300#100
clr_noz_start_x: -1 #130
clr_noz_start_y: 50 #390
clr_noz_len_x: 2  #60
clr_noz_len_y: 30 #45 #50 #2
pa_clr_dis_mm: 25 #35 #50
clr_xy_spd: 4
###quick clr nozzle
clr_noz_quick: True #False #True
clr_quick_high:0.7
clr_xy_quick_spd:100
clr_quick_times:10
clr_quick_react_dis:5

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


[printer]
kinematics: corexy#cartesian
max_velocity: 1000 #600
max_accel: 100000 #8000
max_accel_to_decel: 5000
max_z_velocity: 30
square_corner_velocity: 5.0
max_z_accel: 300

[idle_timeout]
timeout: 99999999

[stepper_x]
step_pin: PC2
dir_pin: !PB9
enable_pin: !PC3
microsteps: 32
rotation_distance: 63.874 #63.810 #63.95 #63.7 #64#40
endstop_pin: !PA11
#endstop_pin: tmc2209_stepper_x:virtual_endstop
#endstop_pin: nozzle_mcu: PB0
position_endstop: 400.5 #406 #400 #-30 #-10.5
position_min: -5 #-30 #-10.5
position_max: 406 #400 #400 #248
homing_speed: 40
homing_retract_dist:0 #10

[tmc2209 stepper_x]
uart_pin:PB12
driver_SGTHRS: 80#100#88
uart_address:3 
interpolate: True
run_current: 2.0 #1.2#0.65
sense_resistor: 0.150
stealthchop_threshold: 0
diag_pin: ^PB10

[stepper_y]
step_pin: PB8
dir_pin: PB7
enable_pin: !PC3
microsteps: 32
rotation_distance: 64.024 #63.912 #63.95 #63.7 #64 #60
endstop_pin: !PA12
#endstop_pin: tmc2209_stepper_y:virtual_endstop
position_endstop: 401 #400 #-15 #-5.5
position_min: -1 #-5 #-15 #-5.5
position_max: 401 #400 #225
homing_speed: 40
homing_retract_dist:0

[tmc2209 stepper_y]
uart_pin:PB13
driver_SGTHRS: 80
uart_address:3 
interpolate: True
run_current: 2.0 #1.2 #0.6
sense_resistor: 0.150
stealthchop_threshold: 0
diag_pin: ^PB11

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

[tmc2209 stepper_z]
uart_pin: PB14
interpolate: True
run_current: 0.8
uart_address:3 
# hold_current:0.5
stealthchop_threshold: 0
sense_resistor: 0.150
diag_pin: PB0 #^PB14
# driver_SGTHRS: 0


[filament_switch_sensor filament_sensor]
switch_pin: !PC6
pause_on_runout: true
# runout_gcode: PAUSE

[output_pin _Height_module2]
pin: PA7
value: 1.0

[extruder]
max_extrude_only_distance:1000
max_extrude_cross_section:80
pressure_advance = 0.04
step_pin: nozzle_mcu: PB5
dir_pin: nozzle_mcu: PB4 #!nozzle_mcu: PB4
enable_pin: !nozzle_mcu: PB2
microsteps: 16
# gear_ratio: 42:12
rotation_distance: 6.72 #7.53
nozzle_diameter: 0.400
filament_diameter: 1.750
heater_pin: nozzle_mcu: PB8
sensor_type: EPCOS 100K B57560G104F
sensor_pin: nozzle_mcu: PA0
control = pid
pid_kp = 20.145
pid_ki = 1.919 
pid_kd = 52.881
min_temp: 0
max_temp: 320 # Set to 300 for S1 Pro


[tmc2209 extruder]
uart_pin: nozzle_mcu: PB10
# tx_pin: nozzle_mcu: PB11
run_current: 0.6 #0.7
sense_resistor: 0.15
stealthchop_threshold: 0
uart_address:3 


[accel_chip_proxy]
adxl345_cs_pin: nozzle_mcu:PA4
adxl345_spi_speed: 5000000
adxl345_axes_map: x,-z,y
adxl345_spi_software_sclk_pin: nozzle_mcu:PA5
adxl345_spi_software_mosi_pin: nozzle_mcu:PA7
adxl345_spi_software_miso_pin: nozzle_mcu:PA6

lis2dw_cs_pin: nozzle_mcu:PA4
lis2dw_spi_speed: 5000000
lis2dw_axes_map: x,-z,y
lis2dw_spi_software_sclk_pin: nozzle_mcu:PA5
lis2dw_spi_software_mosi_pin: nozzle_mcu:PA7
lis2dw_spi_software_miso_pin: nozzle_mcu:PA6

[resonance_tester]
accel_chip: accel_chip_proxy
accel_per_hz: 50
probe_points: 200,200,10


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
max_temp: 110
#temp_offset_flag = True

[temperature_sensor mcu_temp]
sensor_type: temperature_mcu
min_temp: 0
max_temp: 100


#############FAN OLD CONFIG
[controller_fan MCU_fan] # включаем обдув после включения драйверов
pin: PB1
max_power: 1.0
fan_speed: 1
kick_start_time: 0
stepper: stepper_x



[heater_fan nozzle_fan]
pin: !nozzle_mcu: PB3
max_power: 1.0
shutdown_speed: 0
cycle_time: 0.1
hardware_pwm: False
kick_start_time: 0.100
off_below: 0.0
heater: extruder
fan_speed: 1.0
heater_temp: 60.0
[output_pin en_nozzle_fan]
pin: nozzle_mcu: PB7
pwm: False
value: 1.0

###喷头前面风扇

[multi_pin part_fans]
pins:!nozzle_mcu:PB15,!nozzle_mcu:PA9

[multi_pin en_part_fans]
pins:nozzle_mcu:PB6,nozzle_mcu:PB9

[fan_generic part]
pin: multi_pin:part_fans
enable_pin: multi_pin:en_part_fans
cycle_time: 0.0100
hardware_pwm: false




###led
[output_pin green_pin]
pin: PA0
value: 0.0
[output_pin red_pin]
pin: PC1
value: 0.0
[output_pin yellow_pin]
pin: PA1
value: 1.0
[output_pin light_pin] #  освещение камеры принтера. косяк прошивки креалити.
pin: !PC0
pwm: True
cycle_time: 0.010
value: 1.0


[filter]
hft_hz: 1
lft_k1: 0.95
lft_k1_oft: 0.95
lft_k1_cal: 0.95

[dirzctl]
use_mcu: mcu
step_base: 2


[bed_mesh]
speed: 350 #350
mesh_min: 5,5        #need to handle head distance with bl_touch
mesh_max: 395,395 #215,215       #max probe range
probe_count: 8,8 #6,6 #7,7
fade_start: 3.0#1
fade_end: 10
fade_target: 0
mesh_pps:2,2
algorithm: bicubic
bicubic_tension: 1

[exclude_object]

EOF

}


rollback_fix() {
    if [ -f "/usr/data/printer_data/config/gcode_macro.cfg.bak" ] && [ -f "/usr/data/printer_data/config/printer.cfg.bak" ]; then
        mv /usr/data/printer_data/config/gcode_macro.cfg.bak /usr/data/printer_data/config/gcode_macro.cfg
        mv /usr/data/printer_data/config/printer.cfg.bak /usr/data/printer_data/config/printer.cfg
        echo "Исправления откатаны."
    else
        echo "Нет бэкапов для отката."
    fi
}

while true; do
    show_menu
    read -p "Выберите пункт: " choice
    case $choice in
        1) install_fix ;;
        2) rollback_fix ;;
        3) exit 0 ;;
        *) echo "Неверный выбор" ;;
    esac
    read -p "Нажмите Enter для продолжения..."
done
