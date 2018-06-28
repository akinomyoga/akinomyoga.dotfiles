# -*- mode: sh; mode: sh-bash -*-

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

if [[ ! $NOBLE && -s $_dotfiles_blesh_path && $- == *i* ]]; then
  bleopt_char_width_mode=emacs
  if source "$_dotfiles_blesh_path" --noattach; then
    bleopt indent_offset=2
    bleopt decode_isolated_esc=esc
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
  source "$_dotfiles_mshex_path"/shrc/bashrc_common.sh
  if [[ $- == *i* ]]; then
    case ${HOSTNAME%%.*} in
    (vaio2016) mshex/set-prompt '\e[31m' '\e[m' ;;
    (dyna2018) mshex/set-prompt '\e[32m' '\e[m' ;;
    (*)        mshex/set-prompt '\e[m' '\e[m' ;;
    esac

    mwg_cdhist_config_BubbleHist=1
  fi

  [[ $OSTYPE == cygwin ]] &&
    source "$_dotfiles_mshex_path"/shrc/bashrc_cygwin.sh

  #----------------------------------------------------------------------------
  # setup path

  source "$_dotfiles_mshex_path"/shrc/path.sh
  PATH.prepend /usr/local/sbin:/usr/sbin
  PATH.prepend /usr/local/bin:/usr/bin:/bin
  PATH.prepend "$HOME/bin:$HOME/.mwg/bin:$HOME/local/bin"

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

#------------------------------------------------------------------------------

(($_ble_bash)) && ble-attach
