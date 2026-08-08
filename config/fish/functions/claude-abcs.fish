function claude-abcs --description 'Claude Code using the ABCS client account'
    env CLAUDE_CONFIG_DIR="$HOME/.claude-abcs" "$HOME/.local/bin/claude" $argv
end
