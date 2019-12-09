#!/usr/bin/env zsh

export PATH="$PATH:/home/chris/.dotnet/tools"

# core 3
alias efcore3='dotnet tool uninstall --global dotnet-ef && dotnet tool install --global dotnet-ef --version 3.0.0'
alias core3='export DOTNET_ROOT=~/.dotnetvm/master/dotnet-sdk-3.0.100-linux-x64/dotnet && export PATH=~/.dotnetvm/master/dotnet-sdk-3.0.100-linux-x64/:$PATH && dotnet --version && efcore3'
