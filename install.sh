#!/bin/bash

set -e

dest=~/.dotfiles
id=~/.ssh/id_ed25519

if [ ! -f "$id" ]; then
   echo "$id is not present. They can be found in Slack.  Exiting..."
   exit;
fi

git clone --recursive git@github.com:carcer/dotphiles.git $dest
cd $dest
git checkout envs/framework

sh ./quick.sh