# My dotfiles

## Prep 

set env variable for where the dotfiles repo is cloned

```sh
git clone git@github.com:gotha/dotfiles.git ~/Document/dotfiles
cd ~/Documents/dotfiles
DOTFILES_PATH=$(pwd)
```

## Hammerspoon

```sh
rm -rf .hammerspoon
ln -s $DOTFILES_PATH/.hammerspoon ~/.hammerspoon
```

and refresh config.

## Tmux 

```sh
ln -s $DOTFILES_PATH/.tmux.conf ~/.tmux.conf
```

start `tmux` and press `preffix` + `I` to install the required plugins

if you want to change the `prefix` from `Ctrl+B` to `Ctrl+<space>` uncomment he first several lines and restart tmux


! Note: If you are using OSX, By default `Ctrl+<space>` is used as shortcut for switching between 'input sources' (a.k.a the keyboard layout), if you want to use it as tmux prefix you have to change the shortcut to something else, I personally change it to `Option+<space>`.


## Vim/NeoVim

First install [vim-plug](https://github.com/junegunn/vim-plug)

then open `nvim` and run `:PlugInstall`

### Plugin dependencies

[shime/livedown](https://github.com/shime/vim-livedown) plugin depends on `livedown`

```sh
npm install -g livedown
```

## Zsh

install `zsh` via package manager, [ohmyzsh](https://ohmyz.sh/#install) and [powerlevele10k](https://github.com/romkatv/powerlevel10k#oh-my-zsh)

