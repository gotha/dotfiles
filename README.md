# My dotfiles

## Prep 

set env variable for where the dotfiles repo is cloned

```sh
git clone git@github.com:gotha/dotfiles.git ~/Document/dotfiles
cd ~/Documents/dotfiles
DOTFILES_PATH=$(pwd)
```

## Hammerspoon

### Configure

```sh
rm -rf ~/.hammerspoon
ln -s $DOTFILES_PATH/.hammerspoon ~/.hammerspoon
```

### Cheatsheet

The prefix is `Ctrl + Option + Cmd`

| shortcut               | effect                                                                  |
| -----------------------|-------------------------------------------------------------------------|
| `prefix + 0`           | "maximize" or resize current window                                     |
| `prefix + 9`           | send window to the other screen (assumes that you have only 2 monitors) |
| `prefix + left arrow`  | resize window to fit into the left half of the screen                   |
| `prefix + right arrow` | resize window to fit into the right half of the screen                  |
| `prefix + up arrow`    | resize window to fit into the top half of the screen                    |
| `prefix + down arrow`  | resize window to fit into the bottom half of the screen                 |

## Tmux 

```sh
ln -s $DOTFILES_PATH/.tmux.conf ~/.tmux.conf
```

start `tmux` and press `prefix` + `I` to install the required plugins

if you want to change the `prefix` from `Ctrl+B` to `Ctrl+<space>` uncomment he first several lines and restart tmux


! Note: If you are using OSX, By default `Ctrl+<space>` is used as shortcut for switching between 'input sources' (a.k.a the keyboard layout), if you want to use it as tmux prefix you have to change the shortcut to something else, I personally change it to `Option+<space>`.


## Vim/NeoVim

First install [vim-plug](https://github.com/junegunn/vim-plug)

then open `nvim` and run `:PlugInstall`

### Plugin dependencies

#### Livedown

[shime/livedown](https://github.com/shime/vim-livedown) plugin depends on `livedown`

```sh
npm install -g livedown
```

#### Ack 

[mileszs/ack.vim](https://github.com/mileszs/ack.vim) uses [the_silver_searcher](https://github.com/ggreer/the_silver_searcher) so you have to install it. 

For OSX:

```sh
brew install the_silver_searcher
```

For Arch:

```sh
pacman -S the_silver_searcher
```

## Zsh

install `zsh` via package manager, [ohmyzsh](https://ohmyz.sh/#install) and [powerlevele10k](https://github.com/romkatv/powerlevel10k#oh-my-zsh)

