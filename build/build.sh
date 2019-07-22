#!/bin/bash

function mkcd {
  [[ -d $1 ]] || mkdir -p "$1"
  cd "$1"
}

function build/nproc {
  if type -p nproc &>/dev/null; then
    nproc
  elif [[ -e /proc/cpuinfo ]]; then
    grep processor /proc/cpuinfo | wc -l
  else
    echo 2
  fi
}

function install-from-tarball {
  local sl=/
  local prefix=$1
  local name=${prefix%%[-/]*}
  local binary_name=${prefix//["$sl"]/-}
  local tarname=$2

  local install=$HOME/opt/$prefix
  local install_link=$HOME/bin
  if [[ -s $install/bin/$name ]]; then
    echo "build: \"$prefix\" is already installed" >&2
  else
    if [[ $tarname ]]; then
      if [[ ! -f $tarname ]]; then
        echo "build: the specified file \"$tarname\" not found." >&2
        return 1
      fi
    else
      if [[ -f $binary_name.tar.xz ]]; then
        tarname=$binary_name.tar.xz
      elif [[ -f $binary_name.tar.gz ]]; then
        tarname=$binary_name.tar.gz
      elif [[ -f $binary_name.tar.bz2 ]]; then
        tarname=$binary_name.tar.bz2
      else
        echo "build: failed to find a tar ball for \"$binary_name\"." >&2
        return 1
      fi
    fi

    local dirname=${tarname##*/}; dirname=${dirname%.tar.*}
    local base=$PWD

    ( mkcd /tmp/build &&
        tar xvf "$base/$tarname" &&
        cd "$dirname" &&
        CFLAGS='-O2 -march=native' ./configure --prefix="$install" &&
        make -j$(build/nproc) all &&
        make install &&
        cd .. && /bin/rm -rf /tmp/build/"$dirname" )
  fi && {
    [[ ! -e $HOME/bin/$binary_name ]] &&
      ln -s "$install"/bin/"$name" "$install_link/$binary_name"
    [[ $binary_name == $name-*.*.* && ! -e $install_link/${binary_name%.*} ]] &&
      ( cd "$install_link"
        ln -s "$binary_name" "${binary_name%.*}" )
  }
  return 0
}

install-from-tarball bash-3.0.22
install-from-tarball bash-3.1.23
install-from-tarball bash-3.2.57
install-from-tarball bash-4.0.44
install-from-tarball bash-4.1.17
install-from-tarball bash-4.2.53
install-from-tarball bash-4.3.48
# install-from-tarball bash-4.4
# install-from-tarball bash-4.4.12
install-from-tarball bash-4.4.19
install-from-tarball bash-5.0

install-from-tarball gawk/3.0.6
install-from-tarball gawk/3.1.8
install-from-tarball gawk/4.0.2
install-from-tarball gawk/4.1.4
install-from-tarball gawk/4.2.0
