#!/usr/bin/env bash

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
    if [[ -f $dst ]]; then
      local dstbk=${dst}.old i=0
      while [[ -e $dstbk ]]; do
        dstbk=${dst}.old.$((++i))
      done

      echo "mv $dst $dstbk"
      if ! mv "$dst" "$dstbk"; then
        echo "failed to backup the original file. abort." >&2
      fi
    fi

    if [[ $src != /* ]]; then
      src=$PWD/$src
    fi

    echo "ln -s $src $dst"
    ln -s "$src" "$dst"
  fi
}

command:link-dotfile bashrc ~/.bashrc
