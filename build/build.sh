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
  fi && (
    cd "$install_link"
    local flag_new=
    if [[ ! -e $binary_name ]]; then
      flag_new=1
      ln -s "$install"/bin/"$name" "$binary_name"
    fi

    local flag_relink=
    if [[ $binary_name == $name-*.*.* ]]; then
      if [[ ! -e $install_link/${binary_name%.*} ]]; then
        flag_relink=1
      elif [[ $flag_new ]]; then
        local file patch_level max_patch_level=0
        for file in $install_link/${binary_name%.*}.*; do
          patch_level=${file##*.}
          ((patch_level>max_patch_level)) &&
            max_patch_level=$patch_level
        done
        [[ ${binary_name##*.} == "$max_patch_level" ]] &&
          flag_relink=1
      fi
    fi

    [[ $flag_relink ]] &&
      ln -sf "$binary_name" "${binary_name%.*}"
  )
  return 0
}

## @fn apply-patches bash-5.0.0
function apply-patches {
  local base_dir=$1
  local rex='^([[:alnum:]_]+)-([0-9]+)\.([0-9]+)(\.[0-9]+)?'
  if [[ ! $base_dir =~ $rex ]]; then
    echo "apply-patches: argument #1 ($1) has unexpected form." >&2
    return 1
  fi
  local program=${BASH_REMATCH[1]}
  local version=${BASH_REMATCH[2]}.${BASH_REMATCH[3]}
  local current_patch_level=${BASH_REMATCH[4]#.}

  # (1) patch を当てる対象のソースコード
  local flag_archive_created=
  if [[ ! -d $base_dir ]]; then
    local archive_name=
    if [[ -f $base_dir.tar.xz ]]; then
      archive_name=$base_dir.tar.xz
    elif [[ -f $base_dir.tar.gz ]]; then
      archive_name=$base_dir.tar.gz
    elif [[ -f $base_dir.tar.bz2 ]]; then
      archive_name=$base_dir.tar.bz2
    fi

    [[ $archive_name ]] &&
      tar xf "$archive_name"

    if [[ ! -d $base_dir ]]; then
      echo "apply-patches: failed to find a directory" >&2
      return 1
    fi
    flag_archive_created=1
  fi

  # (2) patch を当てる
  local new_patch_level=$(
    cd "$base_dir"
    local patch_dir=../$program-$version-patches
    local patch_fmt=$program${version//[!0-9]}-%03d
    local i beg=$((current_patch_level+1)) end=999
    for ((i=beg;i<end;i++)); do
      local patch
      printf -v patch "$patch_dir/$patch_fmt" "$i"
      [[ -f $patch ]] || break
      echo "applying patch $patch..." >&2
      if ! patch -p0 < "$patch" >&2; then
        echo "${patch#*/}: failed to apply." >&2
        return 1
      fi
      ((current_patch_level=i))
    done
    echo "$current_patch_level" )
  [[ $new_patch_level ]] || return 1

  # (3) 再圧縮
  local new_dir=$program-$version.$new_patch_level
  if [[ -d $new_dir ]]; then
    echo "apply-patches: the directory \"$new_dir\" already exists." >&2
    return 1
  elif [[ -f $new_dir.tar.xz ]]; then
    echo "apply-patches: the archive \"$new_dir.tar.xz\" already exists." >&2
    return 1
  fi
  mv "$base_dir" "$new_dir"
  tar caf "$new_dir.tar.xz" "$new_dir"
  [[ $flag_archive_created ]] && rm -rf "$new_dir"
  return 0
}

#apply-patches bash-4.4.19

install-from-tarball bash/3.0.22
install-from-tarball bash/3.1.23
install-from-tarball bash/3.2.57
install-from-tarball bash/4.0.44
install-from-tarball bash/4.1.17
install-from-tarball bash/4.2.53
install-from-tarball bash/4.3.48
install-from-tarball bash/4.4.23
# install-from-tarball bash/5.0.7
# install-from-tarball bash/5.0.16
install-from-tarball bash/5.0.18
#install-from-tarball bash/5.1-alpha
install-from-tarball bash/5.1

install-from-tarball gawk/3.0.6
install-from-tarball gawk/3.1.8
install-from-tarball gawk/4.0.2
install-from-tarball gawk/4.1.4
install-from-tarball gawk/4.2.0
install-from-tarball gawk/5.0.1
