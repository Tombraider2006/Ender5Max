
<h3 align="right"><a href="https://t.me/tombraider2006" target="_blank">the author's telegram channel</a></h3>

<h2>my config</h2>

This config after! installing the helper script with my edits.

If you want to repeat, then first you need to

1. install [helper script](https://guilouz.github.io/Creality-Helper-Script-Wiki/helper-script/helper-script-installation/)
2. install the items that are marked with green checkmarks.

3. After that, download the configuration files and replace yours with mine.

If I were you, I would save your files somewhere in advance, if something goes wrong, you can always return them. After replacing, reboot the clipper.

What the interface might look like after installation.

https://github.com/user-attachments/assets/1851a861-b29d-4a3b-ac2f-7861f6cc0bae

Posted for review and discussion.
![](/images/helper.png)

Attention, the latest releases require the virtual_pin module. To do this, simply log in via ssh and run the following commands;

```
cd /usr/share/klipper/klippy/extras
wget --no-check-certificate https://raw.githubusercontent.com/Tombraider2006/K1/main/random/virtual_pins.py

```
**Warning!** this will delete the current printer.cfg acode_macro.cfg and moonraker.conf files from the directory. Make sure you backup the files just in case. Do this only after installing the helper script and the items in it that are listed above!

you can download the latest release like this:

```
cd /usr/data/printer_data/config
rm printer.cfg
rm gcode_macro.cfg
rm moonraker.conf
wget --no-check-certificate https://raw.githubusercontent.com/Tombraider2006/Ender5Max/refs/heads/main/config_my/printer.cfg
wget --no-check-certificate https://raw.githubusercontent.com/Tombraider2006/Ender5Max/refs/heads/main/config_my/gcode_macro.cfg
wget --no-check-certificate https://raw.githubusercontent.com/Tombraider2006/Ender5Max/refs/heads/main/config_my/moonraker.conf

```