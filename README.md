# My dotfiles

## Install

Install [stow](https://www.gnu.org/software/stow/) first.

```sh
git clone git@github.com:gotha/dotfiles.git ~/Document/dotfiles
cd ~/Documents/dotfiles
stow -t ~ .
```

### neovim

Install [vim-plug](https://github.com/junegunn/vim-plug)

```
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

Install all vim plugins

```
nvim +PlugInstall +qall
```


plugin dependencies:

[vim-livedown](https://github.com/shime/vim-livedown) plugin depends on [livedown](https://github.com/shime/livedown)

```sh
npm install -g livedown
```

[mileszs/ack.vim](https://github.com/mileszs/ack.vim) uses [the_silver_searcher](https://github.com/ggreer/the_silver_searcher) so you have to install it.

### tmux

Start `tmux` and press `prefix` + `I` (shift + i) to install the required plugins.


### zsh

Install `zsh` via package manager (it is installed by default on modern osx)

[ohmyzsh](https://ohmyz.sh/#install)

```sh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

[powerlevele10k](https://github.com/romkatv/powerlevel10k#oh-my-zsh)

```sh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)

```
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```



## Usage

### Hammerspoon

The prefix is `Ctrl + Option + Cmd`

| shortcut               | effect                                                                  |
| -----------------------|-------------------------------------------------------------------------|
| `prefix` + `0`         | "maximize" or resize current window                                     |
| `prefix` + `9`         | send window to the other screen (assumes that you have only 2 monitors) |
| `prefix` + ➡️           | resize window to fit into the right half of the screen                   |
| `prefix` + ⬅️           | resize window to fit into the left half of the screen                  |
| `prefix` + ⬆️           | resize window to fit into the top half of the screen                    |
| `prefix` + ⬇️           | resize window to fit into the bottom half of the screen                 |

## Tmux

The prefix in this configuration is `Ctrl + Space`


| shortcut                    | effect                                                      |
| ----------------------------|-------------------------------------------------------------|
| `prefix` + `\|`             | split vertically                                            |
| `prefix` + `_`              | split horizontaly                                           |
| `prefix` + `h` `j` `k` `l`  | move to panel in the selected direction (vim style)         |
| `prefix` + `H` `J` `K` `L`  | resize panel in selected direction (vim style)              |
| `prefix` + `c`  	      | create new workspace (tab)                                  |
| `prefix` + `C`  	      | create new window                                           |
| `prefix` + `n`  	      | next window                                                 |
| `prefix` + `p`    	      | previous window                                             |
| `prefix` + `w`  	      | view all windows                                            |
| `prefix` + `S`  	      | save current session                                        |
| `prefix` + `R`  	      | restore last saved session (useful after restart)           |
| `prefix` + `d`  	      | detach from current tmux session (you can reattach with `tmux attach`) |
| `prefix` + `[`  	      | enter in normal mode (navigate with hjkl, select text with `shift + v` and copy with `y`)|
| `prefix` + `{`  	      | switch the places of left and right panel                   |


