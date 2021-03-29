#!/bin/bash

id=~/.ssh/id_ed25519
if [ ! -f "$id" ]; then
    echo "$id is not present. Exiting..."
    exit;
fi
git clone --recursive git@github.com:carcer/dotphiles.git ~/.dotfiles-test

#// Run deploy
#// install nvm
#// run dotsync