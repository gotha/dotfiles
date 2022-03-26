#!/usr/bin/env bash

which op
if [ $? -ne 0 ]; then
  echo "please install onepassword cli first"
  exit 1
fi

EMAIL=$1
if [ -z "$EMAIL" ]; then
  echo "Please enter your 1password e-mail"
  echo "Usage: ./get-keys.sh <e-mail>"
  exit 1
fi

if [ -z "$OP_SESSION_my" ]; then
  op signin my.1password.com "$EMAIL"
  eval $(op signin my)
fi

op get document id_rsa.pub >~/.ssh/id_rsa.pub
op get document id_rsa >~/.ssh/id_rsa
