#!/usr/bin/env zsh

export PATH="$PATH:/home/chris/.dotnet/tools"

# core 3
alias efcore3='dotnet tool uninstall --global dotnet-ef && dotnet tool install --global dotnet-ef --version 3.0.0'
alias core3='export DOTNET_ROOT=~/.dotnetvm/master/dotnet-sdk-3.0.100-linux-x64/ && export PATH=~/.dotnetvm/master/dotnet-sdk-3.0.100-linux-x64/:$PATH && dotnet --version && efcore3'

# core 2.2
alias efcore22='dotnet tool uninstall --global dotnet-ef && dotnet tool install --global dotnet-ef --version 2.2.0'
alias core22='export DOTNET_ROOT=~/.dotnetvm/master/dotnet-sdk-2.2.207-linux-x64/ && export PATH=~/.dotnetvm/master/dotnet-sdk-2.2.207-linux-x64/:$PATH && dotnet --version && efcore22'

