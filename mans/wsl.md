Прошивка картографера с помощью Wsl из Windows


### Установка wsl


Открываем командную строку windows пишем `cmd` в поиске правой кнопкой мыши на иконке и ищем строку **запуск с правами администратора**

```
wsl --install
```
*Примечание:
Приведенная выше команда работает только в том случае, если WSL не установлен вообще. Если вы запускаете `wsl --install` и видите текст справки WSL, попробуйте `wsl --list --online` просмотреть список доступных дистрибутивов и запустить `wsl --install -d <DistroName>` для установки дистрибутива.*

Подробно про  установку можно [почитать тут](https://learn.microsoft.com/ru-ru/windows/wsl/install) 


### Устанавливаем ubuntu 

```
wsl.exe --install Ubuntu-24.04
```

Запускаем
```
wsl.exe -d Ubuntu-24.04
```

 вписываем имя пользователя и пароль, пароль отображаться не будет, это нормально, повторяем ввод пароля

будет правильным сразу проверить и установить обновления

```
sudo apt update && sudo apt upgrade -y
```

выходим пока из установленного дистрибутива, так как нам надо еще доустановить пакет для usb подключения.  

```
 exit
```
### Увидеть USB в Linux 

Устанавливаем пакет для того чтобы видеть подключенные usb устройства 

```
 winget install --interactive --exact dorssel.usbipd-win
```

Список всех USB-устройств, подключенных к Windows, откройте PowerShell **в режиме администратора** и введите следующую команду. После перечисления устройств выберите и скопируйте идентификатор шины устройства, который вы хотите подключить к WSL.
```
usbipd list
```

![](/images/pid_list.jpg)

**Обратите внимание на номер BUSID у себя, он может отличаться от того что в мануале**

Перед присоединением USB-устройства необходимо использовать команду usbipd bind для совместного использования устройства, что позволяет подключить его к WSL. Для этого требуются права администратора. Выберите идентификатор шины устройства, который вы хотите использовать в WSL, и выполните следующую команду. После выполнения команды убедитесь, что устройство используется совместно, повторно выполнив команду `usbipd list`.


```
usbipd bind --busid 1-2
```

![](/images/bind_usb.jpg)

Чтобы подключить USB-устройство, выполните следующую команду. (Вам больше не нужно использовать командную строку администратора с повышенными привилегиями.) Убедитесь, что командная строка WSL открыта, чтобы поддерживать работу  виртуальной машины WSL 2. Обратите внимание, что до тех пор, пока USB-устройство подключено к WSL, оно не может использоваться Windows. После подключения к WSL USB-устройство может использоваться любым дистрибутивом, работающим как WSL 2. Убедитесь, что устройство подключено с помощью `usbipd list`. В командной строке WSL выполните команду lsusb , чтобы убедиться, что USB-устройство отображается и может взаимодействовать с помощью средств Linux.

```
usbipd attach --wsl --busid <busid>
```
![](/images/usb_attach.jpg)

Откройте Ubuntu 

```
wsl
```

вводим 
```
lsusb
```

![](/images/lsusb_.jpg)


Вы увидите только что подключенное устройство и сможете взаимодействовать с ним с помощью обычных средств Linux. 

подробно можно [почитать тут](https://learn.microsoft.com/ru-ru/windows/wsl/connect-usb)


### Прошивка картографера

Вам необходимо выполнить следующие команды для установки необходимых пакетов.

```
sudo apt-get update
sudo apt-get install virtualenv python3-dev python3-pip python3-setuptools libffi-dev build-essential git dfu-util
```

ПО для картографера

```
git clone "https://github.com/Klipper3d/klipper" $HOME/klipper
git clone "https://github.com/Cartographer3D/cartographer-klipper.git" $HOME/cartographer-klipper
```
чтобы прошить прошивку 5.1.0, вам нужно скачать последнюю версию master и переключиться на нее. Это можно сделать следующим образом:

```
cd $HOME/cartographer-klipper
git fetch
git switch master
git reset --hard origin/master
```
Настройка виртуального окружения Klipper

```
virtualenv --system-site-packages $HOME/klippy-env
$HOME/klippy-env/bin/pip3 install -r $HOME/klipper/scripts/klippy-requirements.txt
```

Включить загрузчик

```
CARTO_DEV=$(ls /dev/serial/by-id/usb-* | grep "IDM\|Cartographer" | head -1)
cd $HOME/klipper/scripts
sudo -E $HOME/klippy-env/bin/python -c "import flash_usb as u; u.enter_bootloader('$CARTO_DEV')"
```

**Предупреждение**

Если вы получили сообщение типа `ls: cannot access '/dev/serial/by-id/usb-*': No such file or directory`, это означает, что  ваш кабель Carto неправильно подключен.

Вы должны увидеть сообщение вроде:

``
Entering bootloader on /dev/serial/by-id/usb-Cartographer_614e_16000C000F43304253373820-if00
``

Прошивка

```
CATAPULT_DEV=$(ls /dev/serial/by-id/usb-katapult*)
sudo -E $HOME/klippy-env/bin/python $HOME/klipper/lib/canboot/flash_can.py -f $HOME/cartographer-klipper/firmware/v2-v3/survey/5.1.0/Survey_Cartographer_K1_USB_8kib_offset.bin -d $CATAPULT_DEV
```

Вы должны увидеть следующий вывод:

```
Attempting to connect to bootloader
CanBoot Connected
Protocol Version: 1.0.0
Block Size: 64 bytes
Application Start: 0x8002000
MCU type: stm32f042x6
Flashing '/home/ubuntu/cartographer-klipper/firmware/v2-v3/survey/5.1.0/Survey_Cartographer_K1_USB_8kib_offset.bin'...

[##################################################]

Write complete: 22 pages
Verifying (block count = 338)...

[##################################################]

Verification Complete: SHA = BB45B9575AC57FFF03CA5FE09186DB479E09BF53
CAN Flash Success
```