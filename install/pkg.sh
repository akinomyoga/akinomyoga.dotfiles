#!/bin/bash

function mkd { [[ -d $1 ]] || mkdir -p "$1"; }
function ble/is-function { delclare -f "$1" &>/dev/null; }
function ble/function#try {
  ble/is-function "$1" || return 127
  "$@"
}
#------------------------------------------------------------------------------

PKGDIR=$PWD/package
TMPDIR=${XDG_RUNTIME_DIR:-/dev/shm/$UID}/build
OPTDIR=$HOME/opt

function pkg/download {
  local url=$1
  local file=${1%%'?'*}; file=${file##*/}
  mkd "$PKGDIR"
  wget -nv "$url" -O "$PKGDIR/$file"
}

function pkg/extract {
  local tar
  for tar in "$PKGDIR/$1".*; do
    case $tar in
    (*.tar.gz|*.tgz)  tar xf "$tar" ;;
    (*.tar.xz|*.txz)  tar xf "$tar" ;;
    (*.tar.bz2|*.tbz) tar xf "$tar" ;;
    (*.zip) unzip "$tar" ;;
    (*) continue ;;
    esac

    cd "$1"; return "$?"
  done
}

## @fn pkg/parse-name-version package
##   @var[out] name version
function pkg/parse-name-version {
  local rex='([^-]+)-([0-9].*)'
  if [[ $1 =~ $rex ]]; then
    name=${BASH_REMATCH[1]}
    version=${BASH_REMATCH[2]}
    return 0
  fi

  name=$1
  version=$(
    for path in "$PKGDIR/$name"-*; do echo "${path#${PKGDIR}/$name-}"; done |
      sed -En 's/(\.tar\.(gz|xz|bz2|zst)|\.zip)$//p' |
      sort -Vr | head -1)
  [[ $version ]] && return 0

  echo "pkg.sh: unknown package '$1'" >&2
  return 2
}

function pkg/get-installed-version {
  local rex='([^-]+)-([0-9].*)'
  if [[ $1 =~ $rex ]]; then
    name=${BASH_REMATCH[1]}
    version=${BASH_REMATCH[2]}
    [[ -d $OPTDIR/$name/$version ]] && return 0
  fi

  name=$1
  version=$(
    for path in "$OPTDIR/$name"/*/; do path=${path#${OPTDIR/$name}}; echo "${path%/}"; done |
      sort -Vr | head -1)
  [[ $version ]] && return 0

  echo "pkg.sh: unknown package '$1'" >&2
  return 2
}

function install/type:configure {
  local name version
  pkg/parse-name-version "$1" || return "$?"; shift

  local -a configure_options=()
  while (($#)); do
    local arg=$1; shift
    case $arg in
    (-Wc,) IFS=, eval "configure_options+(\${arg#-Wc,})" ;;
    esac
  done

  local prefix=$OPTDIR/$name/$version
  ( mkcd "$TMPDIR" &&
      pkg/extract "$1" &&
      ./configure --prefix="$prefix" "${configure_options[@]}" &&
      make -j all &&
      make -j install )
}

function pkg/install {
  local package=$1
  local name version
  pkg/parse-name-version "$package" || return 1
  [[ -d $OPTDIR/$name/$version ]] && return 0

  local -a dependencies=()
  ble/function#try "pkg:$name/depends"
  local depend
  for depend in "${dependencies[@]}"; do
    install "$depend" || return 1
  done

  if ble/is-function "pkg:$package/install"; then
    if ! "pkg:$package/install" "$name-$version"; then
      echo "pkg: failed to install '$name'." >&2
      return 1
    fi
    return 0
  elif ble/is-function "pkg:$name/install"; then
    if ! "pkg:$name/install" "$name-$version"; then
      echo "pkg: failed to install '$name'." >&2
      return 1
    fi
    return 0
  fi

  echo "pkg: rule not found for '$name'." >&2
  return 2
}

#------------------------------------------------------------------------------

function pkg:giflib/get {
  local url='https://downloads.sourceforge.net/project/giflib/giflib-5.2.1.tar.gz'
  local query='?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fgiflib%2Ffiles%2Fgiflib-5.2.1.tar.gz%2Fdownload%3Fuse_mirror%3Djaist&ts=1599077287'
  pkg/download "$url$query"
}
function pkg:giflib/install {
  local name version
  pkg/parse-name-version "$1" || return 1
  ( mkcd "$TMPDIR" &&
      pkg/extract "$1" &&
      make -j PREFIX="$OPTDIR/$name/$version" all &&
      make -j PREFIX="$OPTDIR/$name/$version" install )
}

function pkg:tiff/get { pkg/download https://download.osgeo.org/libtiff/tiff-4.1.0.tar.gz; }
function pkg:tiff/install { install/type:configure tiff; }

function pkg:gmp/get { pkg/download https://ftp.gnu.org/gnu/gmp/gmp-6.2.0.tar.xz; }
function pkg:gmp/install { install/type:configure gmp; }

function pkg:nettle/get {
  case $1 in
  (nettle-2.5)
    pkg/download https://ftp.gnu.org/gnu/nettle/nettle-2.5.tar.gz ;;
  (*)
    pkg/download https://ftp.gnu.org/gnu/nettle/nettle-3.6.tar.gz
  esac
}
function pkg:nettle/depends {
  #dependencies=(gmp) # 実は不要?
  dependencies=()
} 
function pkg:nettle/install { install/type:configure "$1"; }

function pkg:gnutls/get { pkg/download https://ftp.gnu.org/gnu/gnutls/gnutls-3.1.5.tar.xz; }
function pkg:gnutls/depends { dependencies=(nettle-2.5); }
function pkg:gnutls/install { install/type:configure gnutls -Wc,--with-libnettle-prefix=$OPTDIR/nettle/2.5; }

function pkg:emacs/get { pkg/download http://mirrors.kernel.org/gnu/emacs/emacs-27.1.tar.xz; }
function pkg:emacs/depends { dependencies=(giflib tiff gnutls); }
function pkg:emacs/install {
  local -x CPPFLAGS= LDFLAGS= PKG_CONFIG_PATH=

  local name version
  pkg/get-installed-version gnutls || return 1
  PKG_CONFIG_PATH=$OPTDIR/$name/$version/lib/pkgconfig

  pkg/get-installed-version tiff || return 1
  CPPFLAGS+=" -I $OPTDIR/$name/$version/include"
  LDFLAGS+=" -L $OPTDIR/$name/$version/lib"
  LDFLAGS+=" -Wl,-rpath,$OPTDIR/$name/$version/lib"

  pkg/get-installed-version giflib || return 1
  CPPFLAGS+=" -I $OPTDIR/$name/$version/include"
  LDFLAGS+=" -L $OPTDIR/$name/$version/lib"
  LDFLAGS+=" -Wl,-rpath,$OPTDIR/$name/$version/lib"

  install/type:configure emacs
}

# .mwg/src よりコピーする
function pkg/clone:mwg {
  local name=$1
  if [[ -d ~/.mwg/src/$name ]]; then
    git clone --recursive "$HOME/.mwg/src/$name" "$TMPDIR/$name"
  else
    git clone --recursive "git@github.com:akinomyoga/$name.git" "$TMPDIR/$name"
  fi || return 1
  ( cd "$TMPDIR/$name"; git gc )
  ( cd "$TMPDIR" &&
    tar caf "$PKGDIR/$name.tar.xz" "./$name" &&#
    rm -rf "$TMPDIR/$name" )
}

function pkg:akinomyoga.dotfiles/get { pkg/clone:mwg akinomyoga.dotfiles; }
function pkg:ble.sh/get   { pkg/clone:mwg ble.sh  ; }
function pkg:mshex/get    { pkg/clone:mwg mshex   ; }
function pkg:myemacs/get  { pkg/clone:mwg myemacs ; }
function pkg:colored/get  { pkg/clone:mwg colored ; }
function pkg:contra/get   { pkg/clone:mwg contra  ; }
function pkg:psforest/get { pkg/clone:mwg psforest; }
function pkg:screen/get   { pkg/clone:mwg screen  ; }

function sub:package {
  local package flags=
  for package; do
    if ble/is-function "pkg:$package"/get; then
      "pkg:$package"/get
    else
      echo "pkg.sh: unknown package '$package'" >&2
      flags=e$flags
    fi
  done
  [[ $flags != *e* ]]
}

if (($#==0)); then
  echo "usage: pkg.sh subcommand args..." >&2
  exit 2
elif ble/is-function "sub:$1"; then
  "sub:$@"
else
  echo "pkg.sh: unknown subcommand '$1'" >&2
  exit 2
fi
