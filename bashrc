# -*- mode: sh; mode: sh-bash -*-

case ${HOSTNAME%%.*} in
(padparadscha)
  # Source global definitions
  if [ -f /etc/bashrc ]; then
    . /etc/bashrc
  fi

  # if [[ -f /opt/intel/composer_xe_2013.0.079/bin/ia32/idbvars.sh ]]; then
  #   source /opt/intel/composer_xe_2013.0.079/bin/ia32/idbvars.sh
  # fi
  if [[ -f /opt/intel/composer_xe_2013_sp1.3.174/bin/ia32/idbvars.sh ]]; then
    source /opt/intel/composer_xe_2013_sp1.3.174/bin/ia32/idbvars.sh
  fi ;;

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
    "$HOME"/prog/ble/out/ble.sh
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

dotfiles/find-blesh-path

# for debugging ble.sh

#_dotfiles_blesh_path=~/prog/ble/ble.sh
#_dotfiles_blesh_path=~/.local/share/blesh/ble.sh
#bleopt_suppress_bash_output=
if [[ ! $NOBLE && -s $_dotfiles_blesh_path && $- == *i* ]]; then
  bleopt_char_width_mode=emacs
  source "$_dotfiles_blesh_path" --noattach --rcfile ~/.blerc
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

  source "$_dotfiles_mshex_path"/shrc/path.sh
  PATH.prepend /usr/local/sbin:/usr/sbin
  PATH.prepend /usr/local/bin:/usr/bin:/bin
  PATH.prepend "$HOME/bin:$HOME/.mwg/bin:$HOME/local/bin"

  PATH.append -v MANPATH /usr/share/man:/usr/local/man

  function dotfiles/setup-path-local {
    PATH.prepend -v C_INCLUDE_PATH     ~/local/include # /usr/local/include
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/local/include # /usr/local/include
    PATH.prepend -v LIBRARY_PATH       ~/local/lib     # /usr/local/lib
    PATH.prepend -v LD_LIBRARY_PATH    ~/local/lib     # /usr/local/lib
    PATH.prepend -v PKG_CONFIG_PATH    ~/local/lib/pkgconfig # /usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:/usr/share/lib/pkgconfig
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
  }

  function dotfiles/setup-path:chatoyancy {
    dotfiles/setup-path-local
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

    # for lava
    PATH.prepend -v LD_LIBRARY_PATH "$LSF_LIBDIR"
  }

  function dotfiles/setup-path:neumann {
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

  if declare -f dotfiles/setup-path:"${HOSTNAME%%.*}" &>/dev/null; then
    dotfiles/setup-path:"${HOSTNAME%%.*}"
  elif [[ ${HOSTNAME%%.*} == laguerre* ]]; then
    dotfiles/setup-path:laguerre
  fi

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
    (vaio2016|dyna2018)
      mshex/set-prompt '\e[31m' '\e[m' ;;
    (laguerre*|neumann|mathieu)
      mshex/set-prompt $'\e[38;5;125m' $'\e[m' ;;
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

(($_ble_bash)) && ble-attach
