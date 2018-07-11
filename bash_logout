# ~/.bash_logout -*- mode: sh; mode: sh-bash -*-

case ${HOSTNAME%%.*} in
(padparadscha|chatoyancy)
  dotfiles/close_bg ;;
esac
