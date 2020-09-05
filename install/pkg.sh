#!/bin/bash

function mkd { [[ -d $1 ]] || mkdir -p "$1"; }
function ble/is-function { declare -f "$1" &>/dev/null; }
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
  local file=${1%%'?'*}
  file=$PKGDIR/${file##*/}
  [[ $flags != *f* && -s $file ]] && return 0
  mkd "$PKGDIR"
  wget "$url" -O "$file"
}

function pkg/clone/.readargs {
  flags=
  name=
  path_local=
  path_github=
  while (($#)); do
    local arg=$1; shift
    if [[ $flags != *R* && $arg == -* ]]; then
      case $arg in
      (-l)  path_local=$1; shift ;;
      (-l*) path_local=${arg:2} ;;
      (--github=*) path_github=${arg#*=} ;;
      (--github)   path_github=$1; shift ;;
      (--local=*)  path_local=${arg#*=} ;;
      (--local)    path_local=$1; shift ;;
      (--)  flags=R$flags ;;
      (*)   echo "pkg/clone: unrecognized option '$arg'" >&2
            flags=E$flags ;;
      esac
    else
      name=$arg
    fi
  done
  [[ $flags != *E* ]]
}
function pkg/clone {
  local flags name path_local path_github
  pkg/clone/.readargs "$@"

  local name=$1
  local dst=$PKGDIR/$name.tar.xz
  [[ $flags != *f* && -s $dst ]] && return 1
  if [[ $path_local && -d $path_local ]]; then
    (cd "$path_local"; git gc)
    git clone --recursive "$path_local" "$TMPDIR/$name"
  elif [[ $path_github ]]; then
    git clone --recursive "$path_github" "$TMPDIR/$name"
  fi || return 1
  ( cd "$TMPDIR" &&
    tar caf "$dst" "./$name" &&#
    rm -rf "$TMPDIR/$name" )
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

  ble/is-function "pkg:$name/get" && return 0

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

function pkg/install:configure {
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

function cmd:install {
  local package=$1
  local name version
  pkg/parse-name-version "$package" || return 1
  [[ -d $OPTDIR/$name/$version ]] && return 0

  local -a dependencies=()
  ble/function#try "pkg:$name/depends"
  local depend
  for depend in "${dependencies[@]}"; do
    cmd:install "$depend" || return 1
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

function sub:package {
  local packages flags=
  packages=()
  while (($#)); do
    local arg=$1; shift
    if [[ $arg == -* ]]; then
      case $arg in
      (-f)
        flags=${arg:1:1}$flags ;;
      (--force)
        flags=${arg:2:1}$flags ;;
      (*)
        echo "pkg.sh package: unknown option " >&2
        flags=E$flags
      esac
    else
      local name version
      if pkg/parse-name-version "$arg" && ble/is-function "pkg:$name"/get; then
        packages+=("$arg")
      else
        echo "pkg.sh: unknown package '$arg'" >&2
        flags=E$flags
      fi
    fi
  done
  [[ $flags == *E* ]] && return 1

  local package dependencies depend
  for package in "${packages[@]}"; do
    local name version
    pkg/parse-name-version "$package"

    # 依存関係のチェック
    dependencies=()
    ble/function#try "pkg:$name"/depends "$package"
    ((${#dependencies[@]})) && sub:package "${dependencies[@]}"

    "pkg:$name"/get "$package" || return 1
  done
  return 0
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
function pkg:tiff/install { pkg/install:configure tiff; }

function pkg:gmp/get { pkg/download https://ftp.gnu.org/gnu/gmp/gmp-6.2.0.tar.xz; }
function pkg:gmp/install { pkg/install:configure gmp; }

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
function pkg:nettle/install { pkg/install:configure "$1"; }

function pkg:gnutls/get { pkg/download https://ftp.gnu.org/gnu/gnutls/gnutls-3.1.5.tar.xz; }
function pkg:gnutls/depends { dependencies=(nettle-2.5); }
function pkg:gnutls/install { pkg/install:configure gnutls -Wc,--with-libnettle-prefix=$OPTDIR/nettle/2.5; }

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

  pkg/install:configure emacs
}

function pkg:mpfr/get { pkg/download https://ftp.gnu.org/gnu/mpfr/mpfr-4.1.0.tar.xz; }
function pkg:mpfr/depends { dependencies=(gmp); }
function pkg:mpfr/install {
  pkg/get-installed-version gmp || return 1
  local gmp_prefix=$OPTDIR/gmp/$name/$version

  pkg/install:configure mpfr -Wc,--with-gmp="$gmp_prefix"
}

function pkg:mpc/get { pkg/download https://ftp.gnu.org/gnu/mpc/mpc-1.2.0.tar.gz; }
function pkg:mpc/depends { dependencies=(mpfr gmp); }
function pkg:mpc/install {
  pkg/get-installed-version gmp || return 1
  local gmp_prefix=$OPTDIR/gmp/$name/$version

  pkg/get-installed-version mpfr || return 1
  local mpfr_prefix=$OPTDIR/mpfr/$name/$version

  pkg/install:configure mpc -Wc,--with-mpfr="$mpfr_prefix",--with-gmp="$gmp_prefix"
}

function pkg:gcc/get { pkg/download https://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz; }
function pkg:gcc/depends { dependencies=(mpc mpfr gmp); }
function pkg:gcc/install {
  pkg/get-installed-version gmp || return 1
  local gmp_prefix=$OPTDIR/gmp/$name/$version

  pkg/get-installed-version mpfr || return 1
  local mpfr_prefix=$OPTDIR/mpfr/$name/$version

  pkg/get-installed-version mpc || return 1
  local mpc_prefix=$OPTDIR/mpc/$name/$version

  local -x LD_LIBRARY_PATH=$gmp_prefix/lib:$mpfr_prefix/lib:$mpc_prefix/lib
  pkg/install:configure \
    gcc \
    -Wc,--with-gmp="$gmp_prefix" \
    -Wc,--with-mpfr="$mpfr_prefix" \
    -Wc,--with-mpc="$mpc_prefix" \
    -Wc,--disable-multilib
}

function pkg:git/get { pkg/download https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.28.0.tar.xz; }
function pkg:git/depends { dependencies=(); }
function pkg:git/install { pkg/install:configure git; }

# .mwg/src よりコピーする
function pkg/clone:mwg {
  local name=$1
  pkg/clone "$name" \
            --local="$HOME/.mwg/src/$name" \
            --github="git@github.com:akinomyoga/$name.git"
}

function pkg:akinomyoga.dotfiles/get { pkg/clone:mwg akinomyoga.dotfiles; }
function pkg:ble.sh/get   { pkg/clone:mwg ble.sh  ; }
function pkg:mshex/get    { pkg/clone:mwg mshex   ; }
function pkg:myemacs/get  { pkg/clone:mwg myemacs ; }
function pkg:colored/get  { pkg/clone:mwg colored ; }
function pkg:contra/get   { pkg/clone:mwg contra  ; }
function pkg:psforest/get { pkg/clone:mwg psforest; }
function pkg:screen/get   { pkg/clone:mwg screen  ; }

function pkg:hprism/get {
  pkg/clone hprism --local ~/work/idt/hprism --github git@github.com:akinomyoga/hprism.git
}
function pkg:hydro2jam/get {
  pkg/clone hydro2jam --local ~/work/idt/hydro2jam --github git@github.com:akinomyoga/hydro2jam.git
}
function pkg:pku/get {
  pkg/clone pku --local ~/work/pku --github git@github.com:akinomyoga/pku-work.git
}

#------------------------------------------------------------------------------

if (($#==0)); then
  echo "usage: pkg.sh subcommand args..." >&2
  exit 2
elif ble/is-function "sub:$1"; then
  "sub:$@"
else
  echo "pkg.sh: unknown subcommand '$1'" >&2
  exit 2
fi
