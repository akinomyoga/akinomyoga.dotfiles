# -*- mode: sh; mode: sh-bash -*-

function dotfiles/exec-bash {
  local bash=$1
  [[ $- != *i* || $BASH == $bash ]] && return 0
  [[ -x $bash ]] || return 1
  exec $bash
}
case ${HOSTNAME%%.*} in
(song???)
  dotfiles/exec-bash /opt/bash/5.0.11/bin/bash
  dotfiles/exec-bash ~/bin/bash-5.0 ;;
esac

# Source global definitions
if [[ $OSTYPE != cygwin ]]; then
  # Cygwin の /etc/profile には cd $HOME 等変な物が書かれている。
  if [[ -f /etc/profile ]]; then
    . /etc/profile
  elif [[ -f /etc/bashrc ]]; then
    . /etc/bashrc
  fi
fi

case ${HOSTNAME%%.*} in
(padparadscha)
  # if [[ -f /opt/intel/composer_xe_2013.0.079/bin/ia32/idbvars.sh ]]; then
  #   source /opt/intel/composer_xe_2013.0.079/bin/ia32/idbvars.sh
  # fi
  if [[ -f /opt/intel/composer_xe_2013_sp1.3.174/bin/ia32/idbvars.sh ]]; then
    source /opt/intel/composer_xe_2013_sp1.3.174/bin/ia32/idbvars.sh
  fi ;;

(gell-mann)
  # Source global definitions
  if [ -f /etc/bashrc ]; then
    . /etc/bashrc
  fi
  
  # Uncomment the following line if you don't like systemctl's auto-paging feature:
  # export SYSTEMD_PAGER=
  ;;

(laguerre*)
  # Source global definitions
  if [[ ! $LSF_LIBDIR && -f /etc/profile.local ]]; then
    source /etc/profile.local &>/dev/null
  fi
  source /etc/bashrc &>/dev/null
  source ~/.bashrc_default ;;

esac

umask 022

#------------------------------------------------------------------------------
# initialize ble.sh

function dotfiles/find-blesh-path {
  _dotfiles_blesh_path=

  local -a candidates
  candidates=(
    "$HOME"/.mwg/src/ble.sh/out/ble.sh
    ${XDG_DATA_HOME:+"$XDG_DATA_HOME"/blesh/ble.sh}
    "$HOME"/.local/share/blesh/ble.sh )

  local path
  for path in "${candidates[@]}"; do
    if [[ -s $path ]]; then
      _dotfiles_blesh_path=$path
      break
    fi
  done
}

if [[ ! $NOBLE && $- == *i* ]]; then
  dotfiles/find-blesh-path

  #
  # Selection of devel ble.sh
  #

  _dotfiles_blesh_manual_attach=
  _dotfiles_blesh_devel=~/.mwg/src

  _dotfiles_blesh_version=400
  if ((_dotfiles_blesh_version==300)); then
    _dotfiles_blesh_path=$_dotfiles_blesh_devel/ble-0.3/out/ble.sh
  elif ((_dotfiles_blesh_version==200)); then
    _dotfiles_blesh_path=$_dotfiles_blesh_devel/ble-0.2/out/ble.sh
  elif ((_dotfiles_blesh_version==100)); then
    _dotfiles_blesh_path=$_dotfiles_blesh_devel/ble-0.1/out/ble.sh
  fi
  #_dotfiles_blesh_path=~/.local/share/blesh/ble.sh
  #_dotfiles_blesh_path=~/prog/ble/ble.sh
  #_dotfiles_blesh_path=$_dotfiles_blesh_devel/ble-dev/out/ble.sh

  #
  # Debug settings
  #
  #bleopt_internal_suppress_bash_output=

  [[ -s $_dotfiles_blesh_path ]] &&
    if ((_dotfiles_blesh_version>=400)); then
      source "$_dotfiles_blesh_path"
    elif ((_dotfiles_blesh_version==300)); then
      if [[ $_dotfiles_blesh_manual_attach ]]; then
        source "$_dotfiles_blesh_path" --noattach
      else
        source "$_dotfiles_blesh_path" --attach=prompt
        # Note: The option "--attach=prompt" is an experimental feature.
        #   Basically you should use "--noattach" and manual
        #   "((_ble_bash)) && ble-attach" instead.
      fi
    elif ((_dotfiles_blesh_version==200)); then
      _dotfiles_blesh_manual_attach=1
      source "$_dotfiles_blesh_path" --noattach
    elif ((_dotfiles_blesh_version==100)); then
      _dotfiles_blesh_manual_attach=1
      source "$_dotfiles_blesh_path" noattach
    fi
fi

#------------------------------------------------------------------------------
# load common settings from mshex

function dotfiles/find-mshex-path {
  _dotfiles_mshex_path=

  local path
  for path in "${XDG_DATA_HOME:-$HOME/.local/share}" "$HOME"/.mwg/share; do
    if [[ -d $path/mshex ]]; then
      _dotfiles_mshex_path=$path/mshex
      break
    fi
  done
}

dotfiles/find-mshex-path

if [[ $_dotfiles_mshex_path ]]; then
  #----------------------------------------------------------------------------
  # setup path

  function dotfiles/setup-path-local {
    PATH.prepend -v C_INCLUDE_PATH     ~/local/include # /usr/local/include
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/local/include # /usr/local/include
    PATH.prepend -v LIBRARY_PATH       ~/local/lib{,64}     # /usr/local/lib
    PATH.prepend -v LD_LIBRARY_PATH    ~/local/lib{,64}     # /usr/local/lib
    PATH.prepend -v PKG_CONFIG_PATH    ~/local/lib{,64}/pkgconfig # /usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:/usr/share/lib/pkgconfig
  }
  function dotfiles/prepend-binary-path {
    local prefix=$1
    [[ -d $prefix/bin ]] &&
      PATH.prepend "$prefix"/bin
    [[ -d $prefix/share/man ]] &&
      PATH.prepend -v MANPATH "$prefix"/share/man
  }
  function dotfiles/prepend-runtime-path {
    local prefix=$1
    [[ -d $prefix/lib ]] &&
      PATH.prepend -v LD_LIBRARY_PATH  "$prefix"/lib
    [[ -d $prefix/lib64 ]] &&
      PATH.prepend -v LD_LIBRARY_PATH  "$prefix"/lib64
  }
  function dotfiles/prepend-devel-path {
    local prefix=$1
    [[ -d $prefix/lib ]] &&
      PATH.prepend -v LIBRARY_PATH     "$prefix"/lib
    [[ -d $prefix/lib64 ]] &&
      PATH.prepend -v LIBRARY_PATH     "$prefix"/lib64
    if [[ -d $prefix/include ]]; then
      PATH.prepend -v C_INCLUDE_PATH   "$prefix"/include
      PATH.prepend -v CPLUS_INCLUDE_PATH "$prefix"/include
    fi
    [[ -d $prefix/lib/pkgconfig ]] &&
      PATH.prepend -v PKG_CONFIG_PATH  "$prefix"/lib/pkgconfig
    [[ -d $prefix/lib64/pkgconfig ]] &&
      PATH.prepend -v PKG_CONFIG_PATH  "$prefix"/lib64/pkgconfig
  }

  function dotfiles/setup-path:padparadscha {
    dotfiles/setup-path-local

    # libmwg, libkashiwa
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/opt/libmwg-201509/include{/i686-pc-linux-gnu-gcc-6.3.1+cxx98-debug,}
    PATH.prepend -v LIBRARY_PATH       ~/opt/libmwg-201509/lib/i686-pc-linux-gnu-gcc-6.3.1+cxx98-debug
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/work/libkashiwa/src
    PATH.prepend -v LIBRARY_PATH       ~/work/libkashiwa/out

    export TEXMFHOME="$HOME/.local/share/texmf"
    #export TERMPATH="$HOME/.mwg/terminfo/rosaterm.tc:${TERMPATH:-$HOME/.termcap:/etc/termcap}"

    export GOPATH=$HOME/local/go
  }

  function dotfiles/setup-path:chatoyancy {
    dotfiles/setup-path-local
    export GOPATH=$HOME/go
  }

  function dotfiles/setup-path:vaio2016 {
    # libmwg/libkashiwa
    local libmwg_cxxconfig=i686-cygwin-gcc-5.4.0+cxx98-debug
    PATH.prepend -v CPLUS_INCLUDE_PATH \
                 ~/opt/libmwg-201705/include \
                 ~/opt/libmwg-201705/include/"$libmwg_cxxconfig" \
                 ~/prog/libkashiwa/src
    PATH.prepend -v LIBRARY_PATH \
                 ~/opt/libmwg-201705/lib/"$libmwg_cxxconfig" \
                 ~/prog/libkashiwa/out

    # Visual Studio 2015
    local windir='/cygdrive/c/WINDOWS'
    local prog86='/cygdrive/c/Program Files (x86)'
    local vsdir="$prog86/Microsoft Visual Studio 14.0"
    PATH.append \
      "$prog86/HTML Help Workshop" \
      "$prog86/MSBuild/14.0/bin" \
      "$prog86/Microsoft SDKs/Windows/v10.0A/bin/NETFX 4.6.1 Tools" \
      "$prog86/Windows Kits/10/bin/x86" \
      "$vsdir/Common7/IDE" \
      "$vsdir/Common7/IDE/CommonExtensions/Microsoft/TestWindow" \
      "$vsdir/Common7/Tools" \
      "$vsdir/Team Tools/Performance Tools" \
      "$vsdir/VC/BIN" \
      "$vsdir/VC/VCPackages" \
      "$windir/Microsoft.NET/Framework/v4.0.30319"
  }

  function dotfiles/setup-path:laguerre {
    # default paths
    PATH.prepend -v PKG_CONFIG_PATH \
                 /usr/local/lib/pkgconfig \
                 /usr/local/share/pkgconfig \
                 /usr/lib/pkgconfig \
                 /usr/share/lib/pkgconfig
    PATH.prepend -v MANPATH \
                 /opt/intel/man \
                 /usr/local/share/man \
                 /usr/share/man

    PATH.prepend -v PKG_CONFIG_PATH ~/local/lib/pkgconfig
    PATH.prepend -v MANPATH ~/local
    PATH.prepend -v LD_LIBRARY_PATH \
                 ~/opt/gcc/7.1.0/lib64 ~/opt/gcc/7.1.0/lib \
                 ~/opt/gcc/5.1.0/lib64 ~/opt/gcc/5.1.0/lib \
                 ~/opt/gcc/4.8.3/lib64 ~/opt/gcc/4.8.3/lib \
                 /usr/lib64 /usr/lib

    # for hydrojet
    PATH.prepend -v INCLUDE_PATH         ~/local/include
    PATH.prepend -v LIBRARY_PATH         ~/local/lib
    PATH.prepend -v LD_LIBRARY_PATH      ~/local/lib
    PATH.prepend -v LD_AOUT_LIBRARY_PATH ~/local/lib

    # for own libraries
    PATH.prepend -v CPLUS_INCLUDE_PATH \
                 ~/prog/libkashiwa/src \
                 ~/opt/libmwg-201705/include/x86_64-unknown-linux-gnu-icc-13.1.3+default \
                 ~/opt/libmwg-201705/include \
                 ~/local/include \
                 ~/local/include/laguerre01-icc
    PATH.prepend -v LIBRARY_PATH \
                 ~/prog/libkashiwa/out \
                 ~/opt/libmwg-201705/lib/x86_64-unknown-linux-gnu-icc-13.1.3+default \
                 ~/local/lib

    # glib 2.53
    PATH.prepend -v LD_LIBRARY_PATH \
                 ~/opt/glib/2.53/lib
    PATH.prepend -v PKG_CONFIG_PATH \
                 ~/opt/glib/2.53/lib/pkgconfig

    # 2019-03-30 glibc-2.14.1, tiff-4.0.10
    PATH.append -v LD_LIBRARY_PATH \
                ~/opt/glibc/2.14.1/lib \
                ~/opt/tiff/4.0.10/lib \
                ~/opt/libpng/1.5.30/lib \
                ~/opt/libpng/1.6.36/lib \
                ~/opt/glib/2.58.3/lib
    PATH.append -v PKG_CONFIG_PATH \
                ~/opt/tiff/4.0.10/lib/pkgconfig \
                ~/opt/libpng/1.5.30/lib/pkgconfig \
                ~/opt/libpng/1.6.36/lib/pkgconfig \
                ~/opt/glib/2.58.3/lib/pkgconfig

    # for lava
    PATH.prepend -v LD_LIBRARY_PATH "$LSF_LIBDIR"
  }

  function dotfiles/setup-path:neumann {
    dotfiles/setup-path-local
  }

  function dotfiles/setup-path:gell-mann {
    dotfiles/prepend-binary-path  ~/opt/perl-5.28.0
    dotfiles/prepend-binary-path  ~/opt/git-2.19.0
    dotfiles/prepend-binary-path  ~/opt/openssh-7.8p1
    dotfiles/prepend-binary-path  ~/opt/emacs-26.1
    dotfiles/prepend-binary-path  ~/opt/gcc-8.2.0
    dotfiles/prepend-runtime-path ~/opt/gcc-8.2.0
    dotfiles/setup-path-local
  }

  function dotfiles/setup-path:mathieu {
    # ~/opt/ncurses-6.0
    PATH.prepend -v C_INCLUDE_PATH ~/opt/ncurses-6.0/include
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/opt/ncurses-6.0/include
    PATH.prepend -v LIBRARY_PATH ~/opt/ncurses-6.0/lib

    # ~/opt/xz-5.2.3
    PATH.prepend -v C_INCLUDE_PATH ~/opt/xz-5.2.3/include
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/opt/xz-5.2.3/include
    PATH.prepend -v LIBRARY_PATH ~/opt/xz-5.2.3/lib
    PATH.prepend -v LD_LIBRARY_PATH ~/opt/xz-5.2.3/lib

    # ~/opt/zlib-1.2.1
    PATH.prepend -v C_INCLUDE_PATH ~/opt/zlib-1.2.1/include
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/opt/zlib-1.2.1/include
    PATH.prepend -v LIBRARY_PATH ~/opt/zlib-1.2.1/lib
    PATH.prepend -v LD_LIBRARY_PATH ~/opt/zlib-1.2.1/lib

    # ~/opt/libmwg-20170609
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/opt/libmwg-20170609/include
    PATH.prepend -v LIBRARY_PATH ~/opt/libmwg-20170609/lib
  }

  function dotfiles/setup-path:hankel {
    dotfiles/setup-path-local

    # ~/opt/ncurses-6.0 (ncurses, ncursesw)
    PATH.prepend -v C_INCLUDE_PATH ~/opt/ncurses-6.1/include
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/opt/ncurses-6.1/include
    PATH.prepend -v LIBRARY_PATH ~/opt/ncurses-6.1/lib
  }

  function dotfiles/setup-path:hp2019 {
    dotfiles/setup-path-local
    source ~/opt/dlang/dmd-2.088.0/activate.murase
    export HOMEBREW_PREFIX=$HOME/opt/linuxbrew
    export HOMEBREW_CELLAR=$HOMEBREW_PREFIX/Cellar
    export HOMEBREW_REPOSITORY=$HOMEBREW_PREFIX/Homebrew
    PATH.prepend "$HOMEBREW_PREFIX"/{bin,sbin}
    PATH.prepend -v MANPATH "$HOMEBREW_PREFIX"/share/man
    PATH.prepend -v INFOPATH "$HOMEBREW_PREFIX"/share/info
  }

  function dotfiles/setup-path:song-HP-Z820-Workstation {
    dotfiles/setup-path-local
    LC_ADDRESS=
    LC_ALL=
    LC_IDENTIFICATION=
    LC_MEASUREMENT=
    LC_MONETARY=
    LC_NAME=
    LC_NUMERIC=
    LC_PAPER=
    LC_TELEPHONE=
    LC_TIME=

    alias ssh='ssh -F ~/.ssh/config'
    alias scp='scp -p -F ~/.ssh/config'
    export GIT_SSH_COMMAND='ssh -F ~/.ssh/config'
  }

  source "$_dotfiles_mshex_path"/shrc/path.sh
  PATH.prepend /usr/local/sbin:/usr/sbin
  PATH.prepend /usr/local/bin:/usr/bin:/bin
  PATH.prepend -v MANPATH /usr/share/man:/usr/local/man

  export TEXMFHOME=$HOME/.local/share/texmf

  if [[ $HOSTNAME == song??? || $HOSTNAME == song-* ]]; then
    dotfiles/setup-path:song-HP-Z820-Workstation
  elif declare -f dotfiles/setup-path:"${HOSTNAME%%.*}" &>/dev/null; then
    dotfiles/setup-path:"${HOSTNAME%%.*}"
  elif [[ ${HOSTNAME%%.*} == laguerre* ]]; then
    dotfiles/setup-path:laguerre
  fi

  PATH.prepend "$HOME"/{,.mwg/,local/,.local/}bin

  #----------------------------------------------------------------------------
  # mshex/bashrc_common

  # 中で alias の設定を行う時に参照するので PATH よりも後
  source "$_dotfiles_mshex_path"/shrc/bashrc_common.sh
  if [[ $- == *i* ]]; then
    case ${HOSTNAME%%.*} in
    (padparadscha|chatoyancy)
      if [[ $TTYREC ]]; then
        PS1=$'[\e[4;38;5;202mfoo@bar\e[m \\j \\W]\\$ '
      elif [[ "$TERM" == rosaterm || "$TERM" == *-256color ]]; then
        mshex/set-prompt $'\e[4;38;5;202m' $'\e[m'
      else
        mshex/set-prompt $'\e[4m' $'\e[m'
      fi ;;
    (magnate2016|gauge)
      mshex/set-prompt '\e[32m' '\e[m' ;;
    (vaio2016|dyna2018|letsnote2019)
      mshex/set-prompt '\e[34m' '\e[m' ;;
    (laguerre*|neumann|mathieu|gell-mann|hankel)
      mshex/set-prompt $'\e[38;5;125m' $'\e[m' ;;
    (hp2019|song-*|song???)
      mshex/set-prompt $'\e[31m' $'\e[m' ;;
    (*)
      mshex/set-prompt '\e[m'   '\e[m' ;;
    esac

    mwg_cdhist_config_BubbleHist=1
  fi

  #----------------------------------------------------------------------------
  # others

  source "$_dotfiles_mshex_path"/shrc/less.sh
  [[ $OSTYPE == cygwin ]] &&
    source "$_dotfiles_mshex_path"/shrc/bashrc_cygwin.sh
fi

if [[ $- == *i* ]]; then
  function dotfiles/heartbeat/ps_ppta {
    ps -u "$USER" -o pid,ppid,tty,args | tail -n +2 | awk '{ if ($3 == "??") $3 = "-"; print }'
  }

  function dotfiles/heartbeat/clear {
    local -a pidlist=$(dotfiles/heartbeat/ps_ppta | awk '/[s]tart_bg/ && $2 ~ /^1$|\?/ {print $1}')
    [[ $pidlist ]] && kill $pidlist
    return 0
  }

  function dotfiles/start_bg {
    dotfiles/heartbeat/clear
    local interval=${1:-60}

    [[ ! $STY && $SSH_CONNECTION ]] || return 0
    # [[ $TERM != cygwin ]] && return 0

    local rex='^127\.0\.0\.1 |^192\.168\.0\.'
    [[ $SSH_CONNECTION =~ $rex ]] && return 0

    local tty=$(dotfiles/heartbeat/ps_ppta | awk '$1 == '"$$"' {print $3}')
    [[ $tty != '-' ]] || return 0

    local pid=$(dotfiles/heartbeat/ps_ppta | awk '/[s]tart_bg/ && $3 == "'"$tty"'" {print $1}')
    [[ ! $pid ]] || return 0

    #echo "dotfiles/start_bg ($$): $tty $pid" >> ~/a.txt
    bash -c "while sleep $interval; do echo -n \$'\005'; done # tag: start_bg" &
    disown
  }

  function dotfiles/close_bg {
    dotfiles/heartbeat/clear
    local tty=$(dotfiles/heartbeat/ps_ppta | awk '$1 == '"$$"' {print $3}')
    local pid=$(dotfiles/heartbeat/ps_ppta | awk '/[s]tart_bg/ && $2 == "'"$$"'" && $3 == "'"$tty"'" {print $1}')
    [[ $pid ]] && kill $pid
    return 0
  }

  case ${HOSTNAME%%.*} in
  (padparadscha)
    dotfiles/start_bg 20 ;;

  (chatoyancy)
    dotfiles/start_bg 60 ;;

  (laguerre*)
    alias bj='bjobs -u all'
    alias last='last | grep -v "^ohtsuki .* (00:0[01])"'

    function + {
      # copy&exec to permit editting the original file while execution
      if [[ -f  $1 ]]; then
        local _base=./+.$(date +%Y%m%d).tmp _i=1
        while
          local _tmpname=$_base$((_i++))
          [[ -e $_tmpname ]]
        do :; done
        /bin/cp "$1" "$_tmpname"
        shift
        "$_tmpname" "$@"
        local _ret="$?"
        /bin/rm -f "$_tmpname"
        return "$_ret"
      fi
      
      "$@"
    } ;;
  esac
fi
#------------------------------------------------------------------------------

function a {
  #echo "$*" | bc -l
  awk "BEGIN{print $*;exit;}"
}
## 関数 ble/widget/xword.locate-backward.1 index
##   @param[in] index
##   @var[out] ret
function ble/widget/xword.locate-backward.1 {
  local index=$1
  if ble/syntax/completion-context/.search-last-istat "$((index-1))"; then
    local istat=$ret stat wlen
    ble/string#split-words stat "${_ble_syntax_stat[istat]}"
    if (((wlen=stat[1])>=0)); then
      ((ret=istat-wlen))
      return 0
    fi

    local rex='^[^()<>|&:;$_ble_term_IFS]'
    if ((_ble_syntax_bash_command_BeginCtx[stat[0]])) && 
         [[ ${_ble_edit_str:istat} =~ $rex ]]; then
      ((ret=istat))
      return 0
    fi
  fi
  ret=-1
  return 1
}
function ble/widget/quote-xword {
  [[ $_ble_edit_str ]] || return

  local ret
  ble/widget/xword.locate-backward.1 "$_ble_edit_ind"
  local beg=$ret end=$_ble_edit_ind
  ((beg>=0)) || return
  local ins=${_ble_edit_str:beg:end-beg} q=\' Q="'\''"
  ins="'${ins//$q/$Q}'"

  ble-edit/content/replace "$beg" "$end" "$ins"
  ((_ble_edit_ind=beg+${#ins}-1,
    _ble_edit_mark>${#_ble_edit_str}&&(
      _ble_edit_mark=${#_ble_edit_str})))
  return 0
}
ble-bind -f 'C-x q' quote-xword

[[ $_dotfiles_blesh_manual_attach ]] &&
  ((_ble_bash)) && ble-attach
