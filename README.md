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

## Setup

```console
$ mkdir -p ~/.local/src
$ cd !$
$ git clone git@github.com:akinomyoga/akinomyoga.dotfiles.git
$ cd !$:t:r
$ make install
```
