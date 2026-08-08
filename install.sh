#!/bin/bash

set -e

dest=~/.dotfiles
id=~/.ssh/id_ed25519

if [ ! -f "$id" ]; then
   echo "$id is not present. They can be found in Slack.  Exiting..."
   exit;
fi

git clone --recurse-submodules --branch master git@github.com:carcer/dotphiles.git $dest
cd $dest
git submodule update --init --recursive

sh ./quick.sh
