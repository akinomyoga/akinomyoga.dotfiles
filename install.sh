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

function mkd { [[ -d $1 ]] || mkdir -p "$1"; }
function mkcd { mkd "$1" && cd "$1"; }

MWGDIR=$HOME/.mwg
LOGDIR=$MWGDIR/log/myset
mkd "$LOGDIR"

#------------------------------------------------------------------------------
# update commands

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

function myset/update-git {
  local name="$1"
  local base="$2"
  if [[ -d $name ]]; then
    cd "$name" && git pull
  else
    git clone "$base" && cd "$name"
  fi
}

#------------------------------------------------------------------------------

function install.tic {
  echo registering rosaterm.ti...
  tic terminfo/rosaterm.ti || exit 1
  echo registering screen-256color.ti...
  tic terminfo/screen-256color.ti || exit 1
  touch "$LOGDIR"/tic.stamp
}

#------------------------------------------------------------------------------
# Additional Packages
#
#   ./install.sh yum-minimal
#   ./install.sh yum
#

_yum_packages_minimal='emacs w3m wget screen'
_yum_packages="$_yum_packages_minimal
lynx httpd ntpdate
mono-devel
fuse fuse-libs ntfs-3g
git autoconf automake*
gcc* llvm* clang*
glibc-static cairo-devel ncurses* bison
php php-mbstring php-pear php-opcache php-common php-mysql
nkf"

## @var[out] YUM
function install.yum/determine-packager {
  YUM=yum
  if [[ -f /etc/os-release ]]; then
    # read systemd /etc/os-release
    local ID VERSION_ID
    eval -- $(grep -E '^[[:space:]](ID|VERSION_ID)=' /etc/os-release)
    if [[ $ID == fedora ]]; then
      ((VERSION_ID>=22)) && YUM=dnf
    fi
  elif [[ -f /etc/fedora-release ]]; then
    local release
    IFS= read -r release < /etc/fedora-release
    local rex_release='Fedora release ([0-9]+)'
    if [[ $release =~ $rex_release ]]; then
      local VERSION_ID="${BASH_REMATCH[1]}"
      ((VERSION_ID>=22)) && YUM=dnf
    fi
  fi
}
function install.yum-minimal {
  local YUM; install.yum/determine-packager
  sudo $YUM install $_yum_packages_minimal || exit 1
  touch "$LOGDIR"/yum.stamp
}
function install.yum {
  local YUM; install.yum/determine-packager
  sudo $YUM install $_yum_packages || exit 1
  touch "$LOGDIR"/yum.stamp
}

#------------------------------------------------------------------------------

function install.user-dirs {
  local dir
  mkd "$HOME/User"
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
  ( mkcd "$MWGDIR/src" &&
      myset/update-git mshex https://github.com/akinomyoga/mshex.git &&
      make install )
}

function install.modls {
  local tar="$PWD/pkg/modls.tar.xz"
  ( mkcd "$MWGDIR/src" &&
      tar xJvf "$tar" &&
      cd modls &&
      make all &&
      make install )
}

function install.screen {
  local tar="$PWD/pkg/screen-4.3.1.tar.xz"
  ( mkcd "$MWGDIR/src" &&
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
      mkd ~/.ssh
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
  mkd "$MWGDIR/bin"
  cp -p mwg_pp.awk "$MWGDIR/bin/"
}

function install.myemacs {
  ( mkcd "$MWGDIR/src" &&
      myset/update-git myemacs https://github.com/akinomyoga/myemacs.git &&
      make package-install install &&
      updaterc emacs.new "$HOME/.emacs" "$HOME/.emacs.new" )
}

function show_status {
  local line alpha
  while read line; do
    if [[ $line == 'declare -f install.'* ]]; then
      alpha=${line#declare -f install.}
      [[ $alpha == *[^a-zA-Z_-]* ]] && continue
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
