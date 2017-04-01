function cd() {
	builtin cd "$@" && ls
}
eval `dircolors ~/.dir_colors/dircolors`
