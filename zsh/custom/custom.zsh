function cd() {
	builtin cd "$@" && ls
}
ZSH_AUTOSUGGEST_STRATEGY=default
