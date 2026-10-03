bin
===

`~/bin` is a link to this directory in the dotfiles repo. Anything you put in
`~/bin` lands in the repo as a tracked, or untracked, file.

**Only put Chris's own scripts here,** the ones meant to be committed and
shared across machines.

**Don't install tools or downloaded binaries here** (k3d, kubectl, helm, and
so on). Put them in `~/.local/bin`. That folder is per machine, outside the
repo, and first on `PATH` in every shell, including the non-interactive ones
that `ssh host cmd` and herdr start. `~/bin` isn't on `PATH` there.

If you find a binary here that isn't tracked, move it:

    mv ~/bin/<tool> ~/.local/bin/

To link this directory, `dotsyncrc` has:

    [files]
    ..
    bin:bin
    ..
    [endfiles]
