#!/usr/bin/env zsh

DOTNET_CLI_TELEMETRY_OPTOUT=1
export PATH="$PATH:/home/chris/.dotnet/tools"


# core 5
alias core5='export DOTNET_ROOT=~/.dotnetvm/master/dotnet-sdk-5.0.100-linux-x64/ && export PATH=~/.dotnetvm/master/dotnet-sdk-5.0.100-linux-x64/:$PATH && dotnet --version'

# core 3.1.3
alias efcore313='dotnet tool uninstall --global dotnet-ef && dotnet tool install --global dotnet-ef --version 3.1.3'
alias core313='export DOTNET_ROOT=~/.dotnetvm/master/dotnet-sdk-3.1.201-linux-x64/ && export PATH=~/.dotnetvm/master/dotnet-sdk-3.1.201-linux-x64/:$PATH && dotnet --version'

# core 3.1.2
alias efcore312='dotnet tool uninstall --global dotnet-ef && dotnet tool install --global dotnet-ef --version 3.1.2'
alias core312='export DOTNET_ROOT=~/.dotnetvm/master/dotnet-sdk-3.1.200-linux-x64/ && export PATH=~/.dotnetvm/master/dotnet-sdk-3.1.200-linux-x64/:$PATH && dotnet --version'

# core 3.1.1
alias efcore311='dotnet tool uninstall --global dotnet-ef && dotnet tool install --global dotnet-ef --version 3.1.2'
alias core311='export DOTNET_ROOT=~/.dotnetvm/master/dotnet-sdk-3.1.102-linux-x64/ && export PATH=~/.dotnetvm/master/dotnet-sdk-3.1.102-linux-x64/:$PATH && dotnet --version'

# core 3.1
alias efcore31='dotnet tool uninstall --global dotnet-ef && dotnet tool install --global dotnet-ef --version 3.1.1'
alias core31='export DOTNET_ROOT=~/.dotnetvm/master/dotnet-sdk-3.1.101-linux-x64/ && export PATH=~/.dotnetvm/master/dotnet-sdk-3.1.101-linux-x64/:$PATH && dotnet --version'

# core 3
alias efcore3='dotnet tool uninstall --global dotnet-ef && dotnet tool install --global dotnet-ef --version 3.0.0'
alias core3='export DOTNET_ROOT=~/.dotnetvm/master/dotnet-sdk-3.0.100-linux-x64/ && export PATH=~/.dotnetvm/master/dotnet-sdk-3.0.100-linux-x64/:$PATH && dotnet --version'

# core 2.2
alias efcore22='dotnet tool uninstall --global dotnet-ef && dotnet tool install --global dotnet-ef --version 2.2.0'
alias core22='export DOTNET_ROOT=~/.dotnetvm/master/dotnet-sdk-2.2.207-linux-x64/ && export PATH=~/.dotnetvm/master/dotnet-sdk-2.2.207-linux-x64/:$PATH && dotnet --version'

