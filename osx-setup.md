# My OSX Setup

updated for Big Sur 

## Apps 

First install [homebrew](https://brew.sh/)

These are my base apps
```sh
brew install \
  1password \
  alfred3 \
  cfn-lint \
  checkstyle \
  cloc \
  curl \
  curl-openssl \
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
  httpie \
  hub \
  hugo \
  iterm2 \
  jq \
  kafkacat \
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
  php \
  postman \
  sequel-pro \
  shfmt \
  skype \
  slack \
  spotify \
  tmux \
  transmission \
  vlc \
  wget \
  zsh
```

Install Virtualbox separately since it requires special permissions.

```sh
brew install virtualbox
```

And when we are done with it, we can install docker desktop
```sh
brew cask install docker
```

## Config

### Fix key repeat rate

```sh
defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)
```

[sauce](https://apple.stackexchange.com/questions/10467/how-to-increase-keyboard-key-repeat-rate-on-os-x)


## Polish 

follow the [README](./README.md) to configure your tools with the dotfiles.
