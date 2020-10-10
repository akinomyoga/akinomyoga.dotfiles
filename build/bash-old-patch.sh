#!/usr/bin/env bash

function patch {
  local ver=$1
  local n=${#versions[@]}
  local lastver=${versions[n-1]}
  (
    tar xf ../"bash-$ver.tar.gz"
    cd "bash-$ver"
    git init
    git checkout -b "$ver"
    git add .
    git commit -m "bash-$ver"
    git remote add local ../"bash-$lastver"
    git fetch local
    for b in "${versions[@]}"; do
      git branch "$b" "local/$b"
    done
    #git cherry-pick "$lastver"
  )
}

function git-dist {
  ( cd "$(git rev-parse --show-toplevel)"
    local name=${PWD##*/}
    [[ -d dist ]] || mkdir -p dist
    local archive="dist/$name-$(date +%Y%m%d).tar.xz"
    git archive --format=tar --prefix="./$name/" HEAD | xz > "$archive" )
}

function build {
  local ver=$1
  local n=${#versions[@]}
  local lastver=${versions[n-1]}
  (
    cd "bash-$ver"
    ./configure --prefix="$HOME/opt/bash/$ver" &&
      make &&
      make install &&
      git-dist && mv dist/*.tar.xz ../dist/
  )
}

mkdir -p dist

versions=(2.0{5{,a},4,3})

#patch 2.02.1
#build 2.02.1
versions+=(2.02.1)
#patch 2.02
#build 2.02
versions+=(2.02)
#patch 2.01.1
#build 2.01.1
versions+=(2.01.1)
#patch 2.01
#build 2.01
versions+=(2.01)
#patch 2.0
#build 2.0
versions+=(2.0)
#patch 1.14.7
