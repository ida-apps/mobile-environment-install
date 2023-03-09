#!/bin/bash

getc() {
  local save_state
  save_state="$(/bin/stty -g)"
  /bin/stty raw -echo
  IFS='' read -r -n 1 -d '' "$@"
  /bin/stty "${save_state}"
}

wait_for_user() {
  local c
  echo
  echo "Press ${tty_bold}RETURN${tty_reset}/${tty_bold}ENTER${tty_reset} to continue or any other key to abort:"
  getc c
  # we test for \r and \n because some stuff does \r instead
  if ! [[ "${c}" == $'\r' || "${c}" == $'\n' ]]
  then
    exit 1
  fi
}

abort() {
  local c
  echo
  echo "Press ${tty_bold}ANY KEY${tty_reset} to exit."
  getc c
  exit 1
}

error() {
  printf $(tput setaf 1)"%s\n" "Error: $1" "${@:2}" $(tput sgr0) >&2
  abort
}

exists()
{
  command -v "$1" >/dev/null 2>&1
}

message() {
  printf $(tput setaf 2)"%s\n" "$@" $(tput sgr0) >&2
}