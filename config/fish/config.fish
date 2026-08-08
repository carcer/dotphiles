source /usr/share/cachyos-fish-config/cachyos-config.fish

if status is-interactive; and command -q starship
    starship init fish | source
end

# Keep the CachyOS defaults, but suppress the optional startup greeting.
# function fish_greeting
# end
