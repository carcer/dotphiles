#!/bin/bash

set -e

dest=~/.dotfiles
id=~/.ssh/id_ed25519

if [ ! -f "$id" ]; then
    echo "$id is not present. Exiting..."
    exit;
fi

git clone --recursive git@github.com:carcer/dotphiles.git $dest
cd $dest
git checkout envs/i3
cd $dest
sh ./deploy/linux
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
$dest/dotsync/bin/dotsync -L
