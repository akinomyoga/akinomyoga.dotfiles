#!/bin/bash

function mkcd {
  [[ -d $1 ]] || mkdir -p "$1"
  cd "$1"
}

function install-from-tarball {
  local prefix=$1
  local tarname=$2
  local dirname=${tarname##*/}; dirname=${dirname%.tar.*}
  local base=$PWD

  local install=$HOME/opt/$prefix
  [[ -s $install/bin/bash ]] && return 0

  ( mkcd /tmp/build &&
      tar xvf "$base/$tarname" &&
      cd "$dirname" &&
      CFLAGS='-O2 -march=native' ./configure --prefix="$install" &&
      make -j all &&
      make install &&
      cd .. && /bin/rm -rf /tmp/build/"$dirname") && {
    [[ ! -e $HOME/bin/$prefix ]] &&
      ln -s "$install"/bin/bash ~/bin/"$prefix"
    [[ $prefix == bash-*.*.* && ! -e $HOME/bin/${prefix%.*} ]] &&
      ln -s ~/bin/"$prefix" ~/bin/"${prefix%.*}"
  }
}

install-from-tarball bash-3.0.22 bash-3.0.22.tar.xz
install-from-tarball bash-3.1.23 bash-3.1.23.tar.xz
install-from-tarball bash-3.2.57 bash-3.2.57.tar.gz
install-from-tarball bash-4.0.44 bash-4.0.44.tar.xz
install-from-tarball bash-4.1.17 bash-4.1.17.tar.xz
install-from-tarball bash-4.2.53 bash-4.2.53.tar.gz
install-from-tarball bash-4.3.48 bash-4.3.48.tar.xz
# install-from-tarball bash-4.4    bash-4.4.tar.gz
# install-from-tarball bash-4.4.12 bash-4.4.12.tar.xz
install-from-tarball bash-4.4.19 bash-4.4.19.tar.xz
install-from-tarball bash-5.0 bash-5.0.tar.gz
