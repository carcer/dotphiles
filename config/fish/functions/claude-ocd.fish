function claude-ocd --description 'Claude Code using the OCD account'
    env CLAUDE_CONFIG_DIR="$HOME/.claude-ocd" "$HOME/.local/bin/claude" $argv
end
