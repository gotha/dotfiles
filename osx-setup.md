# My OSX Setup


## Apps 

First install [homebrew](https://brew.sh/)

These are my base apps

```sh
brew install \
  1password \
  alfred \
  authy \
  basictex \
  cfn-lint \
  checkstyle \
  cloc \
  curl \
  docker \
  docker-compose \
  eksctl \
  ffmpeg \
  firefox \
  gimp \
  git \
  git-gui \
  gnu-sed \
  gnu-tar \
  go \
  google-chrome \
  google-java-format \
  hammerspoon  \
  helm \
  httpie \
  hub \
  hugo \
  iterm2 \
  jq \
  kcat \
  karabiner-elements \
  keka \
  kubectx \
  kubie \
  lastpass-cli \
  lua \
  mercurial \
  microsoft-teams \
  ncurses \
  node \
  nvim \
  pandoc \
  php \
  postman \
  sequel-pro \
  shfmt \
  skype \
  slack \
  spotify \
  the_silver_searcher \
  tmux \
  transmission \
  vlc \
  wget \
  zsh
```

```sh
brew install --cask transmission
```

## Config

### Fix key repeat rate

```sh
defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)
```

[sauce](https://apple.stackexchange.com/questions/10467/how-to-increase-keyboard-key-repeat-rate-on-os-x)

## Move dock to the left

Move Dock to the left and set it to hide itself

```sh
defaults write com.apple.dock orientation left
defaults write com.apple.dock autohide -bool TRUE
```

Enable Mission Control on top left hot corner

```sh
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0
```

Minimize apps to application icon

```sh
defaults write com.apple.dock minimize-to-application -bool TRUE
```

Restart Dock to take effect

```sh
killall Dock
```

## Accessibility

Enable 3 finger drag:

```sh
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool TRUE
```

Set shortcut for changing keyboard layout to `Option` + `Space`:

```
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "{enabled = 1; value = { parameters = (32, 49, 524288); type = 'standard'; }; }"
```
