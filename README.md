# My dotfiles

## Install software

Depending on your OS follow one of these guides:
- [ArchLinux](./README-arch.md)
- [Asahi Fedora 39](./README-asahi.md)
- [OS X](./README-osx.md)


## Install configuration

```sh
git clone git@github.com:gotha/dotfiles.git && cd dotfiles
stow -t ~ .
```

### neovim

Install all plugins

```
nvim +PackerSync
```

### tmux

Start `tmux` and press `prefix` + `I` (shift + i) to install the required plugins.

### Vale

```sh
vale sync
```

to update vale styles

### Firefox

to hide tab bar open `about:config` and enable `toolkit.legacyUserProfileCustomizations.stylesheets`
while you are here you can disable Pocket by setting `extensions.pocket.enabled` to `false`.

```sh
cd ~/.mozilla/firefox/ && \
cd $(ls -d *.default-*) && \
ln -s ../xxx.profile-xxx/chrome .
```

