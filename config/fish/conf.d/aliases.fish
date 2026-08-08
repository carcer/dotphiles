# Personal cross-platform shortcuts previously provided by zsh/custom/tools.zsh.
alias cl='clear'

alias g='git'
alias ga='git add'
alias gr='git rm'
alias gf='git fetch'
alias gu='git pull'
alias gup='git pull; and git push'
alias gs='git status --short'
alias gd='git diff'
alias gds='git diff --staged'
alias gdisc='git discard'
alias cia='git commit -am'
alias gp='git push -u'
alias gcl='git clone'
alias gch='git checkout'
alias gbr='git branch'
alias gbrcl='git checkout --orphan'
alias gbrd='git branch -D'
alias gl='git log --no-merges'

alias nr='npm run'
alias ni='npm install'
alias nis='npm install --save'
alias ns='npm search'
alias serve='http-server'
alias server='http-server'

function gcm --description 'Commit with a message'
    git commit -m "$argv"
end

function gcam --description 'Amend commit with a message'
    git commit --amend -m "$argv"
end

function gcp --description 'Commit all changes and push the current branch'
    git commit -a -m "$argv"; and git push -u origin
end

function gi --description 'Generate a .gitignore from toptal.com'
    curl -sL "https://www.toptal.com/developers/gitignore/api/$argv"
end
