# My dotfiles

## Install software

Depending on your OS follow one of these guides:
- [ArchLinux](./README-arch.md)
- [Asahi Fedora 39](./README-asahi.md)
- [OS X](./README-osx.md)


## Install configuration

Get the config:

```sh
git clone https://github.com/gotha/dotfiles.git && cd dotfiles
```

Install it:

```sh
stow -t ~ .
```

### neovim

Install all plugins

```sh
nvim +PackerSync
```

### tmux

Start `tmux` and press `prefix` + `I` (shift + i) to install the required plugins.

or manually:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
killall tmux
tmux
~/.tmux/plugins/tpm/bin/install_plugins
```


### Vale

```sh
vale sync
```

to update vale styles

### Firefox

```sh
./firefox/install.sh
```

## Get ready to contribute

```sh
git remote set-url origin git@github.com:gotha/dotfiles.git
```
