#!/bin/bash

source packages.sh

# Output

error() {
  printf $(tput setaf 1)"%s\n" "Error: $1" "${@:2}" $(tput sgr0) >&2
  abort
}

message() {
  printf $(tput setaf 2)"%s\n" "$@" $(tput sgr0) >&2
}

info() {
  printf $(tput setaf 3)"%s\n" "[INFO]" "$@" $(tput sgr0) >&2
}

export_env_variable() {
  expression=$1

  if "$SHELL" == "/bin/zsh"; then
    echo "$expression" >>~/.zshrc
    source ~/.zshrc
  elif "$SHELL" == "/bin/bash"; then
    echo "$expression" >>~/.bash_profile
    source ~/.bash_profile
  fi
}

# String formatting

if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi

tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

# User input

getc() {
  local save_state
  save_state="$(/bin/stty -g)"
  /bin/stty raw -echo
  IFS='' read -r -n 1 -d '' "$@"
  /bin/stty "${save_state}"
}

abort() {
  local c
  echo
  echo "Press ${tty_bold}ANY KEY${tty_reset} to exit."
  getc c
  exit 1
}

wait_for_user() {
  if [ $SILENT == 0 ]; then
    local c
    echo
    echo "Press ${tty_bold}RETURN${tty_reset}/${tty_bold}ENTER${tty_reset} to continue or any other key to abort..."
    getc c
    # we test for \r and \n because some stuff does \r instead
    if ! [[ "${c}" == $'\r' || "${c}" == $'\n' ]]; then
      exit 1
    fi
  fi
}

ask_user_yn() {
  message=$1
  command=$2

  read -r -p $message response
  if [[ "$response" =~ ^[yY]$ ]]; then
    eval "$command"
  fi
}
