#!/usr/bin/env bash

which op
if [ $? -ne 0 ]; then
  echo "please install onepassword cli first"
  exit 1
fi

eval $(op signin)

if [ ! -d ~/.ssh ]; then
  mkdir ~/.ssh
fi
op document get id_rsa.pub >~/.ssh/id_rsa.pub
op document get id_rsa >~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/id_rsa

op document get npmrc >~/.npmrc
