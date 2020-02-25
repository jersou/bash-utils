#!/usr/bin/env bash

utils:run() {
  set -o errexit
  set -o nounset
  set -o pipefail
  [[ -z ${TRACE:-} ]] || set -o xtrace
  if [[ $# == 0 ]]; then # if the script has no argument, run the main() function
    if [[ ${PIPE_MAIN_STDERR:-true} == true ]]; then
      main 2> >(utils:pipe_error) # colorize stderr (default)
    else
      main
    fi
  elif [[ $* == *--help* ]]; then
    utils:help
  elif utils:list_functions | grep -q "^$1\$"; then # run the function $1
    "$@"
  else
    echo "Unknown function '$1'"
  fi
}

utils:list_functions() {
  if [[ ${IGNORE_UTILS_FUNCTIONS:-true} == true ]]; then
    bash -c ". ${BASH_SOURCE[-1]} ; typeset -F" | cut -d' ' -f3 | grep -v "^utils:"
  else
    bash -c ". ${BASH_SOURCE[-1]} ; typeset -F" | cut -d' ' -f3
  fi
}

utils:help() {
  [[ -z ${HELP_HEADER:-} ]] || utils:log "${HELP_HEADER:-}"
  sh_name=$(basename "${BASH_SOURCE[1]}")
  utils:log "Usage : $sh_name [--help|<function name>]"
  utils:log "Functions ('main' by default) : "
  for func in $(utils:list_functions); do
    help=""
    eval "$(type "${func}" | grep 'declare [h]elp=')"
    [[ -z $help ]] || help=" : $help"
    utils:log "  - ${func}${help}"
  done
}

utils:hr() {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

utils:print_line() {
  if [[ "${line:0:1}" == $'\033' ]]; then
    printf "%s\\n" "${line}"
  else
    ${cmd} "$line"
  fi
}

utils:pipe_color() {
  { set +x; } 2>/dev/null
  cmd=${1}
  while read -r line; do
    utils:print_line
  done
  if [[ -n $line ]]; then
    utils:print_line
  fi
}

utils:print_color() {
  if [[ ${NO_COLOR:-false} == true ]]; then
    echo "${*}" | while read -r l; do
      printf "%s\n" "$l"
    done
  else
    echo "${*}" | while read -r l; do
      printf "${PREFIX_COLOR}%s\e[0m\n" "$l"
    done
  fi
}

utils:log() {
  PREFIX_COLOR="\e[0;32m" utils:print_color "${@}"
}
utils:pipe_log() {
  utils:pipe_color utils:log
}
export -f utils:pipe_log

utils:debug() {
  PREFIX_COLOR="\e[0;36m🐛 " utils:print_color "${@}"
}
utils:pipe_debug() {
  utils:pipe_color utils:debug
}
export -f utils:pipe_debug

utils:error() {
  PREFIX_COLOR="\e[0;31m❌️ " utils:print_color "${@}" 1>&2
}
utils:pipe_error() {
  utils:pipe_color utils:error
}
export -f utils:pipe_error

utils:warn() {
  PREFIX_COLOR="\e[0;33m️⚠️  " utils:print_color "${@}" 1>&2
}
utils:pipe_warn() {
  utils:pipe_color utils:warn
}
export -f utils:pipe_warn

utils:red() {
  PREFIX_COLOR="\e[1;41;39m" utils:print_color "${@}"
}
utils:green() {
  PREFIX_COLOR="\e[1;42m" utils:print_color "${@}"
}
utils:orange() {
  PREFIX_COLOR="\e[1;43m" utils:print_color "${@}"
}
utils:blue() {
  PREFIX_COLOR="\e[1;44m" utils:print_color "${@}"
}
utils:purple() {
  PREFIX_COLOR="\e[1;45m" utils:print_color "${@}"
}
utils:cyan() {
  PREFIX_COLOR="\e[1;46m" utils:print_color "${@}"
}
utils:white() {
  PREFIX_COLOR="\e[1;47m" utils:print_color "${@}"
}

utils:pipe_red() {
  utils:pipe_color utils:red
}
export -f utils:pipe_red

utils:pipe_green() {
  utils:pipe_color utils:green
}
export -f utils:pipe_green

utils:pipe_orange() {
  utils:pipe_color utils:orange
}
export -f utils:pipe_orange

utils:pipe_blue() {
  utils:pipe_color utils:blue
}
export -f utils:pipe_blue

utils:pipe_purple() {
  utils:pipe_color utils:purple
}
export -f utils:pipe_purple

utils:pipe_cyan() {
  utils:pipe_color utils:cyan
}
export -f utils:pipe_cyan

utils:pipe_white() {
  utils:pipe_color utils:white
}
export -f utils:pipe_white

# if the script is not being sourced
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
  IGNORE_UTILS_FUNCTIONS=false
  main() {
    utils:help
  }
  utils:run "$@"
fi
