# ArchLinux config guide

## Install

Install as per usual following the [official install guide](https://wiki.archlinux.org/title/installation_guide) and then inside the chroot environment:

### Bootloader

Install GRUB

```sh
pacman -S grub os-prober efibootmgr
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```

### Network

```sh
pacman -S dhcpcd
systectl enable dhcpcd.service
```

### Install additional software

```sh
pacman -S \
    base-devel \
    git \
    docker \
    less \
    ncdu \
    neovim \ 
    nodejs \
    npm \
    openssh \
    sudo \
    tmux \
    ttf-firacode-nerd \
    unzip \
    vi \
    vim \
    wget \
    zip \
    zsh
```

and reboot

## Post-install

### Configure sudo

```sh
visudo
```

and uncomment the line 
```
%wheel ALL=(ALL:ALL) ALL
```

add your user to `wheel`

```sh
usermod -a -G wheel gotha
```

then you need to logout and log in again or restart.

###  Docker

Allow rootless docker

```sh
usermod -a -G docker gotha
```

then you need to logout and log in again or restart.

```sh
systemctl enable docker
systemctl start docker
```


### Install AUR helper

```sh
pushd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
popd
```

### Install additional software and graphical tools

```sh
yay -S \
    1password \
    alacritty \
    discord \
    eog \
    firefox \
    google-chrome \
    noto-fonts-emoji \
    pavucontrol \
    polkit \
    pulseaudio \
    rofi \
    rofi-emoji \
    slack-desktop \
    spotify \
    sway \
    swaybg \
    swayidle \
    swaylock \
    thunar \
    transmission-gtk \
    vlc \
    waybar \
    wl-clipboard \
    wob \
    xorg-xwayland
```

### Enable wob

```sh
systemctl --user enable --now wob.socket
systemctl --user enable --now wob
```

### Enable pulseaudio

```sh
systemctl --user enable --now pulseaudio
```

### Set zsh as defautl shell

```sh
sudo chsh -s /usr/bin/zsh gotha
```
