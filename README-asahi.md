# Asahi Fedora 39 on M1 mac

## wifi

```sh
nmcli device wifi connect <ssid> password <psswd>
```

## keyboard config

swap `ctrl` and `fn` temporaril

```sh
echo 1 | tee /sys/module/hid_apple/parameters/swap_fn_leftctrl
```

to permanently do it:

```/etc/modprobe.d/hid_apple.conf
options hid_apple swap_fn_leftctrl=1
```

and regenerate initramfs

```sh
dracut --regenerate-all
```

note that you would need `sudo` and `--force` flag to actually write it.

## backlight

```sh
sudo dnf instal dh-autoreconf
git clone https://github.com/perkele1989/light.git
cd light
./configure && make
sudo make install
```

usage:

```sh
# keyboard
light -s sysfs/leds/kbd_backlight -S 10
# display
light -s sysfs/backlight/apple-panel-bl -S 50
```

## start graphical interface automatically

In case you chose Asahi Fedora 'minimal' install, it wont automatically start the GUI

```sh
sudo systemctl set-default graphical.target
```

reset if you get tired of GUI

```sh
sudo systemctl set-default multi-user.target
```


## console fonts

To increase the size, edit /etc/vconsole.conf and specify a larger font size, such as (the font name is important):

```
FONT="latarcyrheb-sun32"
```

Then update grub for the change to take effect

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```

## enable DRM

to listen to spotify and such

```sh
sudo dnf install widevine-installer
widevine-installer
```

To watchwatch netflix you also need to change your user agent to `Chromium OS`

Firefox plugin: https://addons.mozilla.org/en-US/firefox/addon/user-agent-string-switcher/


## disable startup sound

https://discussion.fedoraproject.org/t/is-it-possible-to-silence-the-boot-sound/99993

```sh
sudo dnf install asahi-nvram
sudo asahi-nvram write system:StartupMute=%01
```

## disable grub boot menu

edit `/etc/default/grub` and set

```
GRUB_TIMEOUT=0
```

Then update grub for the change to take effect

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```

## credits

some of these tips were documented at: https://github.com/leifliddy/asahi-fedora-builder
