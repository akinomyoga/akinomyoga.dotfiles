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
_yum_packages=(
  $_yum_packages_minimal

  dnf-plugin-system-upgrade

  # Compilers
  llvm\* clang\* bison
  # gcc\*  # 何故か Fedora 27 で動かない

  # Build tools / debugger / VMS
  make git lldb gdb
  autoconf automake* libtool cmake

  # Libraries
  glibc-static cairo-devel ncurses\*
  xz-devel eigen3-devel gsl-devel fftw3-devel lapack-devel blas-devel boost-*
  libstdc++-static
  libcurl libcurl-devel
  libXmu-devel libXtst libXtst-devel
  wxGTK-devel wxGTK3-devel
  oniguruma-devel

  # shells / terminals
  bash zsh ksh yash dash tcsh
  tmux xterm

  # editors
  vim nano
  aspell aspell-en

  # 何故か screen で makeinfo が必要
  texlive
  texlive-revtex
  texlive-revtex4
  texlive-elsarticle
  texlive-wrapfig
  texlive-japanese

  # C#
  mono-devel

  # Web / PHP
  lynx httpd nginx ntpdate
  php php-mbstring php-pear php-opcache php-common php-mysql
  # php-mysql # Fedora 27 では何故かない

  # Ruby
  ruby ruby-devel rubygem-rails rubygem-rake

  # Python
  python2-devel python2-numpy python2-scipy
  python3-devel python3-numpy python3-scipy

  # Node
  nodejs npm nodejs-grunt uglify-js

  # Golang
  golang

  # Fuse
  fuse fuse-libs ntfs-3g fuse-sshfs

  # text tools, etc
  gawk nkf jq source-highlight qpdf
  gnuplot xauth xorg-x11-fonts-\*

  # cuda
  # git-svn
  # java-1.8.0-openjdk
  # java-1.8.0-openjdk-devel
  # nfs nfs-tools nfs-utils
  # perf htop memtest86+ zerofree
  # swig
  # postgresql-upgrade
  # smartmontools
  # yp-tools ypbind ypserv
  # cron
)

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
  sudo $YUM install "${_yum_packages[@]}" || exit 1
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

function install.dotfiles {
  ( mkcd "$MWGDIR/src" &&
      myset/update-git akinomyoga.dotfiles https://github.com/akinomyoga/akinomyoga.dotfiles.git &&
      make install )
}

function install.mshex {
  ( mkcd "$MWGDIR/src" &&
      myset/update-git mshex https://github.com/akinomyoga/mshex.git &&
      make install )
}

function install.colored {
  ( mkcd "$MWGDIR/src" &&
      myset/update-git colored https://github.com/akinomyoga/colored.git &&
      make install )
}

function install.screen {
  local url=https://github.com/akinomyoga/screen/releases/download/myoga%2Fv4.6.2/screen-4.6.2.tar.xz
  ( mkcd "$MWGDIR/src" &&
      wget "$url" &&
      tar xJvf "${url##*/}" &&
      cd screen-4.6.2 &&
      ./configure --prefix="$HOME"/local --enable-colors256 &&
      make all &&
      make install )
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
      make package-install install )
}

function install.ble {
  ( mkcd "$MWGDIR/src" &&
      myset/update-git ble.sh https://github.com/akinomyoga/ble.sh.git &&
      make all )
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

declare -a alphas
alphas=()
fUpdate=
while (($#)); do
  declare arg="$1"
  shift
  case "$arg" in
  (--update)
    fUpdate=1 ;;
  (-*)
    echo "myset: unrecognized option \`$arg'." >&2;;
  (*)
    alphas+=("$arg") ;;
  esac
done

declare alpha
for alpha in "${alphas[@]}"; do
  if ! declare -f "install.$alpha" &>/dev/null; then
    echo "myset-install.sh: command $alpha not found" >&2
    continue
  fi

  declare fstamp="$LOGDIR/$alpha.stamp"
  if [[ ! $fUpdate && -e $fstamp ]]; then
    echo "myset-install.sh: $alpha is already installed" >&2
    continue
  fi

  "install.$alpha" && touch "$fstamp"
done
