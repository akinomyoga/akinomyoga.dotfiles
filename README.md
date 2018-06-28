# akinomyoga.dotfiles
dotfiles - my settings for actual hosts

## Requirements

- GNU Bash 3.0+, GNU Make
- [akinomyoga/ble.sh](https://github.com/akinomyoga/ble.sh) - Bash Line Editor
- [akinomyoga/mshex](https://github.com/akinomyoga/mshex) - my shell settings
- [akinomyoga/myemacs](https://github.com/akinomyoga/myemacs) - my emacs settings

### Optional

- source-highlight
- akinomyoga/colored
- [akinomyoga/psforest](https://github.com/akinomyoga/psforest.git) - `ps` with process tree graph

## Download

```console
$ mkdir -p ~/.local/src
$ cd !$
$ git clone git@github.com:akinomyoga/akinomyoga.dotfiles.git
$ cd !$:t:r
```

Do not run the command `make install` since your settings will be overwritten by mine. For example, the default user name and email of Git will be replaced by my name (i.e., Koichi Murase) and my email address (i.e., myoga.murase at gmail.com).
