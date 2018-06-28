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

  #----------------------------------------------------------------------------
  # setup path

  source "$_dotfiles_mshex_path"/shrc/path.sh
  PATH.prepend /usr/local/sbin:/usr/sbin
  PATH.prepend /usr/local/bin:/usr/bin:/bin
  PATH.prepend "$HOME/bin:$HOME/.mwg/bin:$HOME/local/bin"

  PATH.append -v MANPATH /usr/share/man:/usr/local/man

  function dotfiles/setup-path:padparadscha {
    PATH.prepend -v C_INCLUDE_PATH     ~/local/include # /usr/local/include
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/local/include # /usr/local/include
    PATH.prepend -v LIBRARY_PATH       ~/local/lib     # /usr/local/lib
    PATH.prepend -v LD_LIBRARY_PATH    ~/local/lib     # /usr/local/lib
    PATH.prepend -v PKG_CONFIG_PATH    ~/local/lib/pkgconfig # /usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:/usr/share/lib/pkgconfig

    # libmwg, libkashiwa
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/opt/libmwg-201509/include{/i686-pc-linux-gnu-gcc-6.3.1+cxx98-debug,}
    PATH.prepend -v LIBRARY_PATH       ~/opt/libmwg-201509/lib/i686-pc-linux-gnu-gcc-6.3.1+cxx98-debug
    PATH.prepend -v CPLUS_INCLUDE_PATH ~/work/libkashiwa/src
    PATH.prepend -v LIBRARY_PATH       ~/work/libkashiwa/out

    export TEXMFHOME="$HOME/.local/share/texmf"
    #export TERMPATH="$HOME/.mwg/terminfo/rosaterm.tc:${TERMPATH:-$HOME/.termcap:/etc/termcap}"
  }

  function dotfiles/setup-path:chatoyancy {
    PATH.prepend -v C_INCLUDE_PATH     "$HOME/local/include" # /usr/local/include
    PATH.prepend -v CPLUS_INCLUDE_PATH "$HOME/local/include" # /usr/local/include
    PATH.prepend -v LIBRARY_PATH       "$HOME/local/lib"     # /usr/local/lib
    PATH.prepend -v LD_LIBRARY_PATH    "$HOME/local/lib"     # /usr/local/lib
    PATH.prepend -v PKG_CONFIG_PATH    "$HOME/local/lib/pkgconfig" # /usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:/usr/share/lib/pkgconfig
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

  if declare -f dotfiles/setup-path:"${HOSTNAME%%.*}" &>/dev/null; then
    dotfiles/setup-path:"${HOSTNAME%%.*}"
  fi
fi

if [[ $- == *i* ]]; then
  if [[ $OSTYPE == linux-gnu ]]; then
    alias p='ps uaxf'
    alias ls='ls --color=auto'
  fi

  type -t colored &>/dev/null &&
    alias diff='colored -F diff'

  case ${HOSTNAME%%.*} in
  (padparadscha)

    #
    # start_bg
    #
    function dotfiles/start_bg {
      [[ ! $STY && $SSH_CONNECTION ]] || return 0

      local rex='^127\.0\.0\.1 |^192\.168\.0\.'
      [[ $SSH_CONNECTION =~ $rex ]] && return 0

      "$HOME/.mwg/start_bg" 20 &
      disown
    }
    dotfiles/start_bg
  esac
fi
#------------------------------------------------------------------------------

(($_ble_bash)) && ble-attach
