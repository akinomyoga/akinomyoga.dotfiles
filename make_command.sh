#!/usr/bin/env bash

function make/bin/sha256sum {
  if type -t sha256sum &>/dev/null; then
    sha256sum "$@"
  elif type -t gsha256sum &>/dev/null; then
    gsha256sum "$@"
  elif type -t sha256 &>/dev/null; then
    sha256 -r "$@"
  else
    cksum "$@"
  fi
}

# 既知の古い設定ファイルの場合はバックアップしなくて良い
function is-known-file {
  local file=$1
  local -a known_hash
  known_hash=(
    # bashrc
    bd013f17bf349b03ccced3ce92500411d7518ab818bf15cac7c489388f524843

    # bash_logout
    2584c4ba8b0d2a52d94023f420b7e356a1b1a3f2291ad5eba06683d58c48570d

    # screenrc
    5ada607a52e9111ec8f902d8d74af24b830bc21f541edd414156e9765ecd20d1
    a73072ecac6513802f7a53fc4315ba38175a0fbde563b9f52b73681c5d13a023
    4d82d10eb5646d1375ad8a92817e2750d497e927ffdd1256be5429cbf658e751

    # emacs
    8706de289895f47ec7f24f6348e108425b2b3a9d6b6ce5e775376aea3bcffbcd

    # gitconfig
    8634a13e65b96f9869459ca709b746e4e6b5986b13bfc8491d162efc5dbd4b84
    b0a91a1be630d4b55e0dc6fd277936ca53b8d517c4b094076cf6cb013a791835
    52f60887d3d0868b6069904d0a83f2853a020bd848efe28c4c83f607eeb75d47

    # gitignore
    8e712bf84f7a596e96651d281812dfa6a740d9f819ddf968dfe7f864b51f67d5
    7c1039a1062d623628832c6deab1e9919bd75422da73a21a06c81a8ed907dc91

    # aspell.conf
    350c552dea4bc158e82506936727382f58b0178394afa327e08334e41dd7aa2c
  )
  IFS=$'\n' eval 'local rex="${known_hash[*]/#/^}"'
  make/bin/sha256sum "$file" | grep "$rex" &>/dev/null
}

function make/link-dotfile {
  local src=$1
  local dst=$2
  if ! [[ $src && $dst ]]; then
    echo "usage: make.sh link-dotfile source-filename destination-filename"
    return 1
  fi

  if [[ -h $dst && -s $dst ]]; then
    # seems to be already installed
    return
  elif [[ -d $dst ]]; then
    echo "make.sh: failed to install $dst. A directory already exists." >&2
    return 1
  else
    if [[ -s $dst ]]; then
      if is-known-file "$dst"; then
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

function subcommand:install {
  make/link-dotfile bashrc ~/.bashrc
  make/link-dotfile bash_logout ~/.bash_logout
  make/link-dotfile emacs ~/.emacs
  make/link-dotfile screenrc ~/.screenrc
  make/link-dotfile tmux.conf ~/.tmux.conf
  make/link-dotfile blerc ~/.blerc
  make/link-dotfile gitconfig ~/.gitconfig
  make/link-dotfile gitignore ~/.gitignore
  make/link-dotfile aspell.conf ~/.aspell.conf
  make/link-dotfile aspell.en.pws ~/.aspell.en.pws
}

function subcommand:sort-aspell-dictionary {
  local infile=aspell.en.pws
  local tmpfile=$infile.part
  {
    head -1 "$infile"
    tail -n +2 "$infile" | LC_ALL=C sort
  } > $tmpfile &&
    mv "$infile" "$infile~" &&
    mv "$tmpfile" "$infile"
}

if declare -f subcommand:"$1" &>/dev/null; then
  subcommand:"$@"
else
  exit 1
fi
