#!/bin/bash

set -e

dest=~/.dotfiles

cd $dest
sh ./deploy/linux
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
$dest/dotsync/bin/dotsync -L