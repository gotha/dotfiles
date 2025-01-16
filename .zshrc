if [ -f /etc/zshenv ]; then
  source /etc/zshenv
fi

if [ ! -d ~/.zsh-autosuggestions ]; then
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh-autosuggestions
fi
source ~/.zsh-autosuggestions/zsh-autosuggestions.zsh

if [ ! -d ~/.powerlevel10k ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
fi
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/.powerlevel10k/powerlevel10k.zsh-theme

ZSH_THEME="powerlevel10k/powerlevel10k"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# setting path
export PATH="$PATH:${HOME}/.local/bin"

NPM_PACKAGES="${HOME}/.npm-packages"
if [ ! -d $NPM_PACKAGES ]; then
  mkdir -pv $NPM_PACKAGES
fi
export PATH="$PATH:$NPM_PACKAGES/bin"

if [ -f "$HOME/.volta" ]; then 
fi

if [ -d "$HOME/Library/Python/3.9/bin" ]; then
  export PATH="$HOME/Library/Python/3.9/bin:$PATH"
fi

export MANPATH="/usr/local/man:$MANPATH"
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"

if [ -d "$HOME/go/bin" ]; then
  export PATH="$HOME/go/bin:$PATH"
fi

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# enable history
HISTSIZE=10000
SAVEHIST=10000

HISTFILE="$HOME/.zsh_history"
mkdir -p "$(dirname "$HISTFILE")"

setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_DUPS
unsetopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
unsetopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY
unsetopt EXTENDED_HISTORY

# set search in history shortcut
bindkey '^R' history-incremental-search-backward

# vi mode
if [ ! -d ~/.zsh-vi-mode ]; then
  git clone https://github.com/jeffreytse/zsh-vi-mode.git $HOME/.zsh-vi-mode
fi
source $HOME/.zsh-vi-mode/zsh-vi-mode.plugin.zsh

alias vim="nvim"

alias gs="git status"
alias gc="git commit"
alias gd="git diff"
alias ga="git add"
alias gl="git log"

alias docker-compose="docker compose"

if which -a bat &> /dev/null ; then
  alias cat="bat"
fi

if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi

if [ $OSTYPE = "linux-gnu" ]; then
  if [ $XDG_SESSION_TYPE = "wayland" ]; then
    alias pbcopy='wl-copy'
    alias pbpaste='wp-paste'
  else
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
  fi
fi

alias kbc=kubectl
if [ -f "$HOME/.config/zsh/kubectl.zsh" ]; then
  source $HOME/.config/zsh/kubectl.zsh
fi

if [[ "$OSTYPE" =~ darwin ]]; then
  export HOMEBREW_NO_AUTO_UPDATE=1
  export PATH="/opt/homebrew/bin:$PATH"
  export PATH="/opt/homebrew/sbin:$PATH"

  if [ -d  /run/current-system/sw/bin ]; then
    export PATH="/run/current-system/sw/bin:$PATH"
  fi
fi

if [ ! -d ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]; then
  git clone --depth 1 https://github.com/wbthomason/packer.nvim\
    ~/.local/share/nvim/site/pack/packer/start/packer.nvim
fi

if [ ! -d ~/.zsh-syntax-highlighting ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.zsh-syntax-highlighting
fi
source $HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if [ -d ~/.pyenv ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi 

if [ -d ~/.volta ]; then
  export VOLTA_HOME="$HOME/.volta"
  export PATH="$VOLTA_HOME/bin:$PATH"
fi

export PATH="$PATH:$HOME/go/bin"

if [ -d /opt/libtorch ]; then
  export LIBTORCH=/opt/libtorch
  export LD_LIBRARY_PATH=${LIBTORCH}/lib:$LD_LIBRARY_PATH
fi

fpath=(~/.zsh/completion $fpath)
autoload -U compinit
compinit

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi
