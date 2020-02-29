#!/usr/bin/env bash

utils:init() {
  set -o errexit
  set -o nounset
  set -o pipefail
  [[ -z ${TRACE:-} ]] || set -o xtrace
  [[ ${PRINT_STACK_ON_ERROR:-false} == false ]] || trap utils:print_stack_on_error EXIT ERR # at exit
}

utils:run_main() {
  utils:init

  type main >/dev/null 2>&1 || (utils:error "main function doesn't exist" && exit)

  if [[ ${PIPE_MAIN_STDERR:-true} == true ]]; then
    main "$@" 2> >(utils:pipe_error) # colorize stderr (default)
  else
    main "$@"
  fi
}

utils:run() {
  if [[ $# == 0 ]]; then # if the script has no argument, run the main() function
    utils:run_main "$@"
  elif [[ $* == *--help* ]]; then
    utils:help
  elif utils:list_functions | grep -q "^$1\$"; then # run the function $1
    utils:init
    if [[ ${PIPE_MAIN_STDERR:-true} == true ]]; then
      "$@" 2> >(utils:pipe_error) # colorize stderr (default)
    else
      "$@"
    fi
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
  echo "Usage : $sh_name [--help|<function name>]"
  echo "Functions ('main' by default) : "
  for func in $(utils:list_functions); do
    help=""
    eval "$(type "${func}" | grep 'declare [h]elp=')"
    [[ -z $help ]] || help=" : $help"
    echo "  - ${func}${help}"
  done
}

utils:hr() {
  if [[ -z ${TERM:-} ]] && [[ -z ${COLUMNS:-} ]]; then
    COLUMNS=120
  fi
  for ((i = 0; i < ${1:-1}; i++)); do
    printf '%*s\n' "${COLUMNS:-$(tput cols -T "${TERM:-dumb}")}" '' | tr ' ' -
  done
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
  PREFIX_COLOR="\e[0;32mℹ️  " utils:print_color "${@}"
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

utils:stack() {
  utils:red "Stack:"
  local frame_number=1
  while caller $frame_number; do
    frame_number=$((frame_number + 1))
  done | utils:pipe_red
}

utils:print_stack_on_error() {
  exitcode=$?
  if [[ $exitcode != 0 ]]; then
    utils:stack
    utils:orange "exit code = $exitcode"
    exit $exitcode
  fi
}

utils:exec() {
  utils:blue "→ " "$@"
  "$@"
}

utils:print_template() {

  read -d '' template <<'EOF_TEMPLATE' || true
#!/usr/bin/env bash

main() {
  declare help="main function"
  echo "args=$*"
  utils:exec echo message "$(basename "$0")"
  utils:log log message
  utils:debug debug message
  utils:error error message
  utils:warn warn message
  utils:red red message
  utils:green green message
  utils:blue blue message
  utils:exec test "$@"
}

cleanup() {
  declare help="run at exit"
  exitcode=$?
  if [[ $exitcode != 0 ]]; then
    utils:stack
    utils:orange "exit code = $exitcode"
    exit $exitcode
  fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # if the script is not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️  utils:* functions
  trap cleanup EXIT ERR # at exit
  utils:run "$@"
fi

EOF_TEMPLATE

  echo "$template"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # if the script is not being sourced
  IGNORE_UTILS_FUNCTIONS=false
  main() {
    utils:help
  }
  utils:run "$@"
fi
