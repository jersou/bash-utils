#!/usr/bin/env bash
# https://github.com/jersou/bash-utils

utils:init() {
  declare help="init bash options: errexit, nounset, pipefail, xtrace if TRACE==true, trap utils:print_stack_on_error if PRINT_STACK_ON_ERROR==true"
  set -o errexit
  set -o nounset
  set -o pipefail
  set -o errtrace
  shopt -s inherit_errexit
  [[ ${TRACE:-false} != true ]] || set -o xtrace
  [[ ${PRINT_STACK_ON_ERROR:-false} != true ]] || trap utils:print_stack_on_error ERR TERM INT # at exit
}

utils:run_main() {
  declare help="run utils:init and run the main function, add color and use utils:pipe_error for stderr except if PIPE_MAIN_STDERR!=true"
  utils:init

  type main >/dev/null 2>&1 || (utils:error "main function doesn't exist" && exit)

  if [[ ${PIPE_MAIN_STDERR:-true} == true ]]; then
    main "$@" 2> >(utils:pipe_error) # colorize stderr (default)
  else
    main "$@"
  fi
}

utils:run() {
  declare help="run utils:init and run the main function or the function \$1, add color and use utils:pipe_error for stderr except if PIPE_MAIN_STDERR!=true"
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
  declare help="list all functions of the parent script"
  if [[ ${IGNORE_UTILS_FUNCTIONS:-true} == true ]]; then
    bash -c ". ${BASH_SOURCE[-1]} ; typeset -F" | cut -d' ' -f3 | grep -v "^utils:"
  else
    bash -c ". ${BASH_SOURCE[-1]} ; typeset -F" | cut -d' ' -f3
  fi | grep -v '^_'
}

utils:help() {
  declare help="print the help of all functions (the declare help='...')"
  [[ -z ${HELP_HEADER:-} ]] || echo "${HELP_HEADER:-}"
  sh_name=$(basename "${BASH_SOURCE[-1]}")
  echo "Usage : $sh_name [--help | script_function_name [ARGS]...]"
  echo "Functions ('main' by default) : "
  for func in $(utils:list_functions); do
    help=""
    eval "$(type "${func}" | grep 'declare [h]elp=')"
    [[ -z $help ]] || help=" : $help"
    echo "  - ${func}${help}"
  done
}

utils:stack() {
  declare help="print current stack"
  utils:red "Stack:"
  local frame_number=1
  while caller $frame_number; do
    frame_number=$((frame_number + 1))
  done | utils:pipe_red
}

utils:print_stack_on_error() {
  exitcode=$?
  declare help="print stack on error exit"
  if [[ $exitcode != 0 ]]; then
    utils:stack
    utils:orange "exit code = $exitcode"
    exit $exitcode
  fi
}

utils:countdown() {
  for pc in $(seq "$1" -1 1); do
    PRINTF_ENDLINE="            \\r" utils:blue "sleep $pc sec"
    sleep 1
  done
  utils:debug "→ countdown $1 end            "
}

utils:exec() {
  declare help="print parameter with blue background and execute parameters, print time if PRINT_TIME=true"
  if [[ ${PRINT_TIME:-false} == true ]]; then
    utils:blue "→ $(date +%Y-%m-%d-%H.%M.%S) → $*"
    time "$@"
    sleep 0.1
    utils:blue "← $(date +%Y-%m-%d-%H.%M.%S) ← $*"
  else
    utils:blue "→ $(date +%Y-%m-%d-%H.%M.%S) → " "$@"
    "$@"
  fi
}

utils:flock_exec() {
  declare help="run <\$2 ...> command with flock (mutex) on '/var/lock/\$1.lock' file"
  utils:blue "→ flock_exec $1"
  lock_file="/var/lock/$1.lock"
  (
    utils:orange "→ wait $lock_file"
    flock -x 9
    utils:green "→ got $lock_file"
    shift
    "$@"
  ) 9>"$lock_file" # fd > 9 doesn't work with zsh
}

#  "$@" = "end" --standalone -s --error=msg1 file0 --error=msg2 -error=errr --error msg3 -e=msg4 -e msg5 -eat=msg6 -a msg7 -t msg8 "file 0" file1 file2 "file 3" -- file4 -file5 --error=msg9 file6 --end
#  utils:has_param "standalone" "$@"
#  → exit code is
#  utils:has_param "a" "$@"
#  → exit code is
#  utils:has_param "t" "$@"
#  → exit code is
#  utils:has_param "unknown" "$@"
#  → exit code is
#  utils:has_param "error|e" "$@"
#  → exit code is
utils:has_param() {
  param_names=(${1//|/ })
  shift
  declare -a list
  while [[ $# -gt 0 ]]; do
    if [[ "${param_names:-}" == "" ]]; then
      if [[ $1 == "--" ]]; then
        shift
        if [[ $# -gt 0 ]]; then
          return 0
        else
          return 1
        fi
      else
        if [[ $1 =~ ^[^-].*$ ]]; then
          return 0
        fi
        shift
      fi
    else
      for param_name in "${param_names[@]}"; do
        case $1 in
        --)
          return 1
          ;;
        --${param_name} | --${param_name}=*)
          if [[ $1 =~ ^(--${param_name})=(.*$) ]]; then
            return 0
          fi
          ;;
        --*) ;;
        -*=*)
          if [[ "${#param_name}" == 1 ]] && [[ $1 =~ ^(-[^=]*${param_name}[^=]*)=(.*$) ]]; then
            return 0
          fi
          ;;
        esac
      done
      shift || true
    fi
  done
  return 1
}

#  "$@" = --standalone -s --error=msg1 file0 --error=msg2 -error=errr --error msg3 -e=msg4 -e msg5 -eat=msg6 -a msg7 -t msg8 "file 0" file1 file2 "file 3" -- file4 -file5 --error=msg9 file6 --end
#  utils:get_params "standalone" "$@"
#  → print "true"
#  utils:get_params "unknown" "$@"
#  → print nothing
#  utils:get_params "error|e" "$@"
#  → print
#  utils:get_params "a" "$@"
#  → print
#  utils:get_params "t" "$@"
#  → print
#  utils:get_params "" "$@"
#  → print
#  utils:get_params "error" "$@"
#  → print
#  utils:get_params "error " "$@"
#  → print
utils:get_params() {
  IFS='|' read -ra param_names <<<"$1" # split first param by | and keep spaces
  shift
  declare -a list
  while [[ $# -gt 0 ]]; do
    if [[ "${param_names:-}" == "" ]]; then
      if [[ $1 == "--" ]]; then
        shift
        list+=("${@}")
        shift $#
      else
        if [[ $1 =~ ^[^-].*$ ]]; then
          list+=("$1")
        fi
        shift
      fi
    else
      for param_name in "${param_names[@]}"; do
        if [[ "${param_name: -1}" == " " ]]; then
          param_name="${param_name::-1}"
          permit_space_key_value_separator=true
        else
          permit_space_key_value_separator=false
        fi
        case $1 in
        --)
          shift $#
          break
          ;;
        --${param_name}=*)
          if [[ $1 =~ ^(--${param_name})=(.*$) ]]; then
            list+=("${BASH_REMATCH[2]}")
            break
          fi
          ;;
        --${param_name})
          if [[ $permit_space_key_value_separator == true ]]; then
            list+=("${2}")
            shift
          else
            list+=(true)
          fi
          break
          ;;
        --*) ;;
        -*=*)
          if [[ "${#param_name}" == 1 && $1 =~ ^(-[^=]*${param_name}[^=]*)=(.*$) ]]; then
            list+=("${BASH_REMATCH[2]}")
            break
          fi
          ;;
        -*)
          if [[ "${#param_name}" == 1 && $1 =~ ^-[^=]*${param_name}[^=]* ]]; then
            if [[ $permit_space_key_value_separator == true ]]; then
              list+=("${2}")
              shift
            else
              list+=(true)
            fi
            break
          fi
          ;;
        esac
      done
      shift || true
    fi
  done
  if [[ "${UTILS_GET_FIRST_PARAM:-false}" == "true" ]]; then
    echo "${list[1]}"
  else
    for arg in "${list[@]}"; do
      echo "$arg"
    done
  fi
}

utils:get_param() {
  UTILS_GET_FIRST_PARAM=true utils:get_params "$@"
}

utils:print_template() {
  declare help="print a bash template"

  read -r -d '' template <<'EOF_TEMPLATE' || true
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
  exitcode=$?
  declare help="print the stack on error exit"
  if [[ $exitcode != 0 ]]; then
    utils:stack
    utils:orange "exit code = $exitcode"
    return $exitcode
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

########################################################################################################################

utils:hr() {
  declare help="print N horizontal line, N=1 by default, N is the first parameter"
  if [[ -z ${TERM:-} ]] && [[ -z ${COLUMNS:-} ]]; then
    COLUMNS=120
  fi
  for ((i = 0; i < ${1:-1}; i++)); do
    printf '%*s\n' "${COLUMNS:-$(tput cols -T "${TERM:-dumb}")}" '' | tr ' ' -
  done
}

utils:log() {
  declare help=$'print parameters in green : \e[0;32mℹ️  parameters\e[0m'
  PREFIX_COLOR="\e[0;32mℹ️  " _print_color "${@}"
}

utils:pipe_log() {
  declare help=$'print each line of stdin in green : \e[0;32mℹ️  stdin\e[0m'
  _pipe_color utils:log
}
export -f utils:pipe_log

utils:debug() {
  declare help=$'print parameters in blue : \e[0;36m🐛  parameters\e[0m'
  PREFIX_COLOR="\e[0;36m🐛 " _print_color "${@}"
}
utils:pipe_debug() {
  declare help=$'print each line of stdin in blue : \e[0;36m🐛  stdin\e[0m'
  _pipe_color utils:debug
}
export -f utils:pipe_debug

utils:error() {
  declare help=$'print parameters in red to stderr : \e[0;31m❌  parameters\e[0m'
  PREFIX_COLOR="\e[0;31m❌️ " _print_color "${@}" 1>&2
}
utils:pipe_error() {
  declare help=$'print each line of stdin in red to stderr : \e[0;31m❌  stdin\e[0m'
  _pipe_color utils:error
}
export -f utils:pipe_error

utils:warn() {
  declare help=$'print parameters in orange to stderr : \e[0;33m️⚠️  parameters\e[0m'
  PREFIX_COLOR="\e[0;33m️⚠️  " _print_color "${@}" 1>&2
}
utils:pipe_warn() {
  declare help=$'print each line of stdin in orange to stderr : \e[0;33m️⚠️  stdin\e[0m'
  _pipe_color utils:warn
}
export -f utils:pipe_warn

utils:red() {
  declare help=$'print parameters with red background : \e[1;41;39mparameters\e[0m'
  PREFIX_COLOR="\e[1;41;39m" _print_color "${@}"
}
utils:green() {
  declare help=$'print parameters with green background : \e[1;42mparameters\e[0m'
  PREFIX_COLOR="\e[1;42m" _print_color "${@}"
}
utils:orange() {
  declare help=$'print parameters with orange background : \e[1;43mparameters\e[0m'
  PREFIX_COLOR="\e[1;43m" _print_color "${@}"
}
utils:blue() {
  declare help=$'print parameters with blue background : \e[1;44mparameters\e[0m'
  PREFIX_COLOR="\e[1;44m" _print_color "${@}"
}
utils:purple() {
  declare help=$'print parameters with purple background : \e[1;45mparameters\e[0m'
  PREFIX_COLOR="\e[1;45m" _print_color "${@}"
}
utils:cyan() {
  declare help=$'print parameters with cyan background : \e[1;46mparameters\e[0m'
  PREFIX_COLOR="\e[1;46m" _print_color "${@}"
}
utils:white() {
  declare help=$'print parameters with white background : \e[1;47mparameters\e[0m'
  PREFIX_COLOR="\e[1;47m" _print_color "${@}"
}

utils:pipe_red() {
  declare help=$'print each line of stdin with red background : \e[1;41;39mparameters\e[0m'
  _pipe_color utils:red
}
export -f utils:pipe_red

utils:pipe_green() {
  declare help=$'print each line of stdin with green background : \e[1;41;39mparameters\e[0m'
  _pipe_color utils:green
}
export -f utils:pipe_green

utils:pipe_orange() {
  declare help=$'print each line of stdin with orange background : \e[1;41;39mparameters\e[0m'
  _pipe_color utils:orange
}
export -f utils:pipe_orange

utils:pipe_blue() {
  declare help=$'print each line of stdin with blue background : \e[1;41;39mparameters\e[0m'
  _pipe_color utils:blue
}
export -f utils:pipe_blue

utils:pipe_purple() {
  declare help=$'print each line of stdin with purple background : \e[1;41;39mparameters\e[0m'
  _pipe_color utils:purple
}
export -f utils:pipe_purple

utils:pipe_cyan() {
  declare help=$'print each line of stdin with cyan background : \e[1;41;39mparameters\e[0m'
  _pipe_color utils:cyan
}
export -f utils:pipe_cyan

utils:pipe_white() {
  declare help=$'print each line of stdin with white background : \e[1;41;39mparameters\e[0m'
  _pipe_color utils:white
}
export -f utils:pipe_white

########################################################################################################################

_print_line() {
  declare help="print the \$line variable with the \$cmd function, use printf if tne line starts with color sequence"
  if [[ "${line:0:1}" == $'\033' ]]; then
    printf "%s\\n" "${line}"
  else
    ${cmd} "$line"
  fi
}

_pipe_color() {
  declare help="use the function \$1 to print each line of stdin"
  { set +x; } 2>/dev/null
  cmd=${1}
  while read -r line; do
    _print_line
  done
  if [[ -n $line ]]; then
    _print_line
  fi
}

_print_color() {
  declare help="print parameters with \$PREFIX_COLOR at the beginning, except if NO_COLOR=true, use PRINTF_ENDLINE=\n by default"
  if [[ ${NO_COLOR:-false} == true ]]; then
    while read -r l; do
      printf "%s%b" "$l" "${PRINTF_ENDLINE:-\\n}"
    done <<<"${*}"
  else
    while read -r l; do
      printf "${PREFIX_COLOR}%s\e[0m%b" "$l" "${PRINTF_ENDLINE:-\\n}"
    done <<<"${*}"
  fi
}

########################################################################################################################

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # if the script is not being sourced
  IGNORE_UTILS_FUNCTIONS=false
  main() {
    utils:help
  }
  utils:run "$@"
fi
