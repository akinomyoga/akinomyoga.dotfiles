#!/bin/bash

#
# ToDo
#
# screen 自前で build する
#   Fedora の用意する screen は変なタイトルを勝手に設定するので。
#
# github account
#
# sshd の設定: Password no Protocol 2
#
#

MWGDIR=$HOME/.mwg
LOGDIR=$MWGDIR/log/myset
mkdir -p "$LOGDIR"

function install.tic {
  echo registering rosaterm.ti...
  tic terminfo/rosaterm.ti || exit 1
  echo registering screen-256color.ti...
  tic terminfo/screen-256color.ti || exit 1
  touch "$LOGDIR"/tic.stamp
}

function install.yum {
  local packages='emacs w3m wget screen'
  sudo yum install $packages || exit 1
  touch "$LOGDIR"/yum.stamp
}

function install.yum2 {
  local packages='
lynx httpd ntpdate
mono-devel
fuse fuse-libs ntfs-3g
git autoconf automake*
gcc* llvm* clang*
glibc-static cairo-devel ncurses* bison
php php-mbstring php-pear php-opcache php-common php-mysql'

  sudo yum install $packages || exit 1
  touch "$LOGDIR"/yum.stamp
}

function install.user-dirs {
  local dir
  mkdir -p "$HOME/User"
  for dir in デスクトップ ダウンロード テンプレート 公開 ドキュメント 音楽 画像 ビデオ; do
    [[ -d $HOME/$dir ]] && mv "$HOME/$dir" "$HOME/User/$dir"
  done

  sed -i '
    s|/デスクトップ|/User&|g
    s|/ダウンロード|/User&|g
    s|/テンプレート|/User&|g
    s|/公開|/User&|g
    s|/ドキュメント|/User&|g
    s|/音楽|/User&|g
    s|/画像|/User&|g
    s|/ビデオ|/User&|g
  ' "$HOME/.config/user-dirs.dirs"
}

function install.mshex {
  ( mkdir -p "$MWGDIR/src" &&
      cd "$MWGDIR/src" &&
      git clone https://github.com/akinomyoga/mshex.git &&
      cd mshex &&
      make install )
}

function install.modls {
  local tar="$PWD/pkg/modls.tar.xz"
  (cd "$MWGDIR/src" &&
      tar xJvf "$tar" &&
      cd modls &&
      make all &&
      make install )
}

function install.screenrc {
  if [[ -e $HOME/.screenrc ]]; then
    cp -p screenrc "$HOME/screenrc.new"
  else
    cp -p screenrc "$HOME/.screenrc"
  fi
}

declare alpha
for alpha in "$@"; do
  if ! declare -f "install.$alpha" &>/dev/null; then
    echo "myset-install.sh: command $alpha not found" >&2
    continue
  fi

  declare fstamp="$LOGDIR/$alpha.stamp"
  if [[ -e $fstamp ]]; then
    echo "myset-install.sh: $alpha is already installed" >&2
    continue
  fi

  "install.$alpha" && touch "$fstamp"
done

