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

function updaterc {
  local src="$1"
  local dst="$2"
  local fallback="${3:-${dst%/*}/${src##*/}.new}"
  if [[ -e $dst ]]; then
    diff -q "$dst" "$src" ||
      [[ $fallback != "$dst" ]] && cp -p "$src" "$fallback"
  else
    cp -p "$src" "$dst"
  fi
}

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
  ( mkdir -p "$MWGDIR/src" &&
      cd "$MWGDIR/src" &&
      tar xJvf "$tar" &&
      cd modls &&
      make all &&
      make install )
}

function install.screen {
  local tar="$PWD/pkg/screen-4.3.1.tar.xz"
  ( mkdir -p "$MWGDIR/src" &&
      cd "$MWGDIR/src" &&
      tar xJvf "$tar" &&
      cd screen-4.3.1 &&
      if [[ $OSTYPE == cygwin ]]; then
        CC=/usr/bin/gcc ./configure --prefix="$HOME"/local --enable-colors256 --enable-ut_time
      else
        ./configure --prefix="$HOME"/local --enable-colors256
      fi &&
      make all &&
      make install )
  updaterc screenrc "$HOME/.screenrc"
}
function install.git {
  git config --global core.editor 'emacs -nw'
  git config --global push.default simple
  updaterc gitignore "$HOME/.gitignore" &&
    git config --global core.excludesfile $HOME/.gitignore

  if [[ $USER == murase || $USER == koichi ]]; then
    git config --global user.name 'Koichi Murase'
    git config --global user.email myoga.murase@gmail.com
  fi
}
function install.github {
  # create ~/.ssh/config
  local fconfig=~/.ssh/config
  if [[ ! -e $fconfig ]]; then
    ( umask 077
      mkdir -p ~/.ssh
      echo '# ssh_config' > "$fconfig" )
    echo "myset (install.github): $fconfig is generated"
  fi

  # create ~/.ssh/id_rsa-github
  local fkey=~/.ssh/id_rsa-github@${HOSTNAME%%.*}
  if [[ ! -e $fkey ]]; then
    echo "myset (install.github): generating $fkey..."
    ssh-keygen -t rsa -b 4096 -f "$fkey"
  fi

  if ! grep -q '\bgithub.com\b' "$fconfig"; then
    cat <<EOF >> "$fconfig"

# GitHub (automatically added by myset/install.github)
Host github.com
  HostName github.com
  Port 22
  User git
  IdentityFile $fkey

EOF
    echo "myset (install.github): github.com is added to ssh_config ($fconfig)."
  else
    echo "myset (install.github): ssh_config ($fconfig) seems to already have a github.com entry."
  fi
}
function install.mwgpp {
  mkdir -p "$MWGDIR/bin"
  cp -p mwg_pp.awk "$MWGDIR/bin/"
}

function install.myemacs {
  ( mkdir -p "$MWGDIR/src" &&
      cd "$MWGDIR/src" &&
      git clone https://github.com/akinomyoga/myemacs.git &&
      cd myemacs &&
      make install &&
      updaterc emacs.new "$HOME/.emacs" "$HOME/.emacs.new"
  )
}

function show_status {
  local line alpha
  while read line; do
    if [[ $line == 'declare -f install.'* ]]; then
      alpha=${line#declare -f install.}
      if [[ -e $LOGDIR/$alpha.stamp ]]; then
        echo "  done [32m$alpha[m"
      else
        echo "  todo [31m$alpha[m"
      fi
    fi
  done < <( declare -F )
}

if (($#==0)); then
  {
    echo "usage: ./install.sh name"
    echo
    echo "NAME:"
    show_status
  } >&2
  exit 1
fi

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
