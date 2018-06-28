#!/usr/bin/env bash

# 既知の古い設定ファイルの場合はバックアップしなくて良い
function is-known-file {
  local -a known_hash
  known_hash=(
    # screenrc
    a73072ecac6513802f7a53fc4315ba38175a0fbde563b9f52b73681c5d13a023
    4d82d10eb5646d1375ad8a92817e2750d497e927ffdd1256be5429cbf658e751

    # emacs
    8706de289895f47ec7f24f6348e108425b2b3a9d6b6ce5e775376aea3bcffbcd
  )
  IFS=$'\n' eval 'local rex="${known_hash[*]/#/\^}"'
  sha256sum "$dst" | grep "$rex" &>/dev/null
}

function command:link-dotfile {
  local src=$1
  local dst=$2
  if ! [[ $src && $dst ]]; then
    echo "usage: make.sh link-dotfile source-filename destination-filename"
    return 1
  fi


  if [[ -h $dst ]]; then
    # seems to be already installed
    return
  elif [[ -d $dst ]]; then
    echo "make.sh: failed to install $dst. A directory already exists." >&2
    return 1
  else
    if [[ -s $dst ]]; then
      if is-known-file; then
        echo "make.sh: existing file '$dst' has known contents, so it will be overwritten." >&2
      else
        local dstbk=${dst}.old i=0
        while [[ -e $dstbk ]]; do
          dstbk=${dst}.old.$((++i))
        done

        echo "mv $dst $dstbk"
        if ! mv "$dst" "$dstbk"; then
          echo "failed to backup the original file. abort." >&2
        fi
      fi
    fi

    if [[ $src != /* ]]; then
      src=$PWD/$src
    fi

    echo "ln -sf $src $dst"
    ln -sf "$src" "$dst"
  fi
}

command:link-dotfile bashrc ~/.bashrc
command:link-dotfile bash_logout ~/.bash_logout
command:link-dotfile emacs ~/.emacs
command:link-dotfile screenrc ~/.screenrc
command:link-dotfile blerc ~/.blerc
command:link-dotfile gitconfig ~/.gitconfig
command:link-dotfile gitignore ~/.gitignore
command:link-dotfile aspell.conf ~/.aspell.conf
command:link-dotfile aspell.en.pws ~/.aspell.en.pws
