#!/usr/bin/env bash
# from https://github.com/jersou/bash-utils
# need bash > 4.3 (2014)

# TODO update doc
# TODO refactor
# TODO reduce color functions
# TODO zenity print

utils:init() {
  declare help="init bash options: errexit, nounset, pipefail, xtrace if TRACE==true, trap utils:print_stack_on_error if UTILS_PRINT_STACK_ON_ERROR==true"
  set -o errexit
  set -o nounset
  set -o pipefail
  set -o errtrace
  # workaround to hide "shopt: inherit_errexit: invalid shell option name" bash < v4.4
  shopt -s inherit_errexit 2>/dev/null || true
  if [[ ${TRACE:-false} == true ]]; then
    set -o xtrace
  fi
  if [[ ${UTILS_PRINT_STACK_ON_ERROR:-false} == true ]]; then
    trap utils:print_stack_on_error ERR TERM INT # at exit
  fi
  _init_debug
}

utils:run() {
  declare help="run utils:init and run the main function or the function \$1, add color and use utils:pipe_error for stderr except if PIPE_MAIN_STDERR!=true"
  if [[ $# == 0 ]]; then # if the script has no argument, run the main() function
    utils:run main "$@"
  elif [[ $* == *--help* ]]; then
    utils:help
  elif utils:list_functions | grep -q "^$1\$"; then # run the function $1
    if [[ ${1:-} == "utils:debugger" ]]; then
      UTILS_DEBUG=false
      TRACE=false
    else
      unset UTILS_DEBUG_PIPES
    fi
    utils:init
    if [[ ${UTILS_DEBUG:-false} == true ]]; then
      _run_debug_mode_true "$@" &
      utils:debugger
    else
      if [[ ${PIPE_MAIN_STDERR:-true} == true ]]; then
        "$@" 2> >(utils:pipe_error >&2) # colorize stderr (default)
      else
        "$@"
      fi
    fi
  else
    utils:error "Unknown function '$1'"
    return 1
  fi
  _cleanup_debug
}

utils:list_functions() {
  declare help="utils_params_values all functions of the parent script, set UTILS_FILTER_PRIVATE_FUNCTIONS!= true to list _* functions"
  if [[ ${IGNORE_UTILS_FUNCTIONS:-true} == true ]]; then
    bash -c ". ${BASH_SOURCE[-1]} ; typeset -F" | cut -d' ' -f3 | grep -v "^utils:"
  else
    bash -c ". ${BASH_SOURCE[-1]} ; typeset -F" | cut -d' ' -f3
  fi |
    if [[ "${UTILS_FILTER_PRIVATE_FUNCTIONS:-true}" == "true" ]]; then
      grep -v '^_'
    else
      cat
    fi
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
    UTILS_PRINTF_ENDLINE="            \\r" utils:blue "sleep $pc sec"
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
    utils:blue "→ $(date +%Y-%m-%d-%H.%M.%S) → $*"
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

###################################################### GET PARAMS ######################################################
utils:has_param() {
  # ${@} = --stln -s --err=msg1 file0 --err=msg2 -err=ERROR --err msg3 -e=msg4 -e msg5 -eat=msg6 -a msg7 -t msg8 "file 0" file1 "file 2" -- file4 -file5 --err=msg9 file6 --end
  # utils:has_param "stln" "$@"      # → exit code is 0
  # utils:has_param "a" "$@"         # → exit code is 0
  # utils:has_param "z" "$@"         # → exit code is 1
  # utils:has_param "unknown" "$@"   # → exit code is 1
  # utils:has_param "err|e" "$@"     # → exit code is 0
  # utils:has_param "err |e " "$@"   # → exit code is 0
  # utils:has_param "z " "$@"        # → exit code is 1
  # utils:has_param "--" "$@"          # → exit code is 0
  # utils:has_param "--" -a -e         # → exit code is 1
  declare help="same as 'utils:get_params' but return exit code 0 if the key is found, 1 otherwise"
  param_names=(${1//|/ })
  shift
  declare -a utils_params_values
  while [[ $# -gt 0 ]]; do
    if [[ "${param_names:-}" == "--" ]]; then
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
          if [[ $1 =~ ^(--${param_name}) ]]; then
            return 0
          fi
          ;;
        --*) ;;
        -*=*)
          if [[ "${#param_name}" == 1 ]] && [[ $1 =~ ^(-[^=]*${param_name}[^=]*)=(.*)$ ]]; then
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

utils:get_params() {
  ## "utils:get_params" return the params $1 from $2...
  ##     utils:get_params "error" "$@"
  ##     print "vv" if $@ contains "--error=vv"
  ## if $1 is "--" return all parameters that doesn't start with by '-', the separator "--" can be used to pass param that start with "-" as option "--"
  ## $1 can contains several parameters : "error|e" → match --error=value or -e=value and print "value"
  ## if param in $1 ends with a space, the format "--key value"/"-k value" is supported, "--key=value" /"-k=value" remains valid
  ## repetitions are supported : --error=a1 --error=a2 → print "a1 / a2" (2 lines)
  ##
  ## "$@" = --stln -s --err=msg1 file0 --err=msg2 -err=ERROR --err msg3 -e=msg4 -e msg5 -eat=msg6 -a msg7 -t msg8 "file 0" file1 "file 2" -- file4 -file5 --err=msg9 file6 --end
  ## ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓   "/" is "\n"   ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓
  ## utils:get_params "stln" "$@" # print true
  ## utils:get_params "a" "$@" # print msg6 / true
  ## utils:get_params "e" "$@" # print ERROR / msg4 / true / msg6
  ## utils:get_params "z" "$@" # print ""
  ## utils:get_params "unknown" "$@" # print ""
  ## utils:get_params "err|e" "$@" # print msg1 / msg2 / ERROR / true / msg4 / true / msg6
  ## utils:get_params "err |e " "$@" # print msg1 / msg2 / ERROR / msg3 / msg4 / msg5 / msg6
  ## utils:get_params "z " "$@" # print ""
  ## utils:get_params "--" "$@" # print file0 / msg3 / msg5 / msg7 / msg8 / file 0 / file1 / file 2 / file4 / -file5 / --err=msg9 / file6 / --end
  ## utils:get_params "--" -a -e # print ""
  declare help="print parameter value \$1 from \"\$@\", if \$1 == '--' print last parameters that doesn't start with by '-' ---- $1='e|error' return 'value' for '--error=value' or '-e=value' ---- accept '--error value' and '-e value' if $1='e |error '"
  IFS='|' read -ra param_names <<<"$1" # split first param by | and keep spaces
  shift
  utils_params_values=()
  while [[ $# -gt 0 ]]; do
    if [[ "${param_names:-}" == "--" ]]; then
      if [[ $1 == "--" ]]; then
        shift
        utils_params_values+=("${@}")
        shift $#
      else
        if [[ $1 =~ ^[^-].*$ ]]; then
          utils_params_values+=("$1")
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
          if [[ $1 =~ ^(--${param_name})=(.*)$ ]]; then
            utils_params_values+=("${BASH_REMATCH[2]}")
            break
          fi
          ;;
        --${param_name})
          if [[ ${permit_space_key_value_separator} == true ]]; then
            utils_params_values+=("${2}")
            shift
          else
            utils_params_values+=(true)
          fi
          break
          ;;
        --*) ;;
        -*=*)
          if [[ "${#param_name}" == 1 && $1 =~ ^(-[^=]*${param_name}[^=]*)=(.*$) ]]; then
            utils_params_values+=("${BASH_REMATCH[2]}")
            break
          fi
          ;;
        -*)
          if [[ "${#param_name}" == 1 && $1 =~ ^-[^=]*${param_name}[^=]* ]]; then
            if [[ ${permit_space_key_value_separator} == true ]]; then
              utils_params_values+=("${2}")
              shift
            else
              utils_params_values+=(true)
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
    echo "${utils_params_values[0]}"
  else
    for arg in "${utils_params_values[@]}"; do
      echo "$arg"
    done
  fi
}

_append_params() {
  if [ ${utils_params[$key]+true} ]; then
    utils_params[$key]+=$'\n'"$value"
  else
    utils_params[$key]="$value"
  fi
}

_print_utils_params() {
  for key in "${!utils_params[@]}"; do
    echo "utils_params[$key]=${utils_params[$key]}"
  done
}

_check_no_value_param_found() {
  if [[ $no_value_param_found == true ]]; then
    utils:error "ERROR : param '$1' is placed after parameter that doesn't starts by a '-' : "
    utils:stack
    return 1
  fi
}

utils:parse_parameters() {
  declare help="set utils_params array from \"\$@\" : --error=msg -a=123 -zer=5 opt1 'opt 2' -- file --opt3 →→ utils_params = [error]=msg ; [--]=opt1 / opt 2 / file / --opt3 ; [z]=5 ; [r]=5 ; [e]=5 ; [a]=123 (/ is \n here)"
  unset utils_params
  declare -gA utils_params
  local no_value_param_found=false
  while [[ $# -gt 0 ]]; do
    case $1 in
    --)
      shift
      while [[ $# -gt 0 ]]; do
        key=-- value="$1" _append_params
        shift
      done
      ;;
    --*=*)
      _check_no_value_param_found "$@"
      if [[ $1 =~ ^--(.+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}" value="${BASH_REMATCH[2]}" _append_params
      fi
      ;;
    --*)
      _check_no_value_param_found "$@"
      if [[ $1 =~ ^--(.*)$ ]]; then
        key="${BASH_REMATCH[1]}" value="true" _append_params
      fi
      ;;
    -*=*)
      _check_no_value_param_found "$@"
      if [[ $1 =~ ^-(.+)=(.*)$ ]]; then
        local keys="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        for ((i = 0; i < ${#keys}; i++)); do
          key="${keys:$i:1}" _append_params
        done
      fi
      ;;
    -*)
      _check_no_value_param_found "$@"
      if [[ $1 =~ ^-(.+)$ ]]; then
        local keys="${BASH_REMATCH[1]}"
        value="true"
        for ((i = 0; i < ${#keys}; i++)); do
          key="${keys:$i:1}" _append_params
        done
      fi
      ;;
    *)
      no_value_param_found=true
      key=-- value="$1" _append_params
      ;;
    esac
    shift || true
  done
}

utils:get_param() {
  declare help="same as 'utils:get_params' but return the first result only"
  UTILS_GET_FIRST_PARAM=true utils:get_params "$@"
}
##################################################### PRINT COLORS #####################################################
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

_print_line() {
  declare help="print the \$line variable with the \$cmd function, use printf if tne line starts with color sequence"
  # TODO make regex [[:blank:]]*\033
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
  declare help="print parameters with \$PREFIX_COLOR at the beginning, except if NO_COLOR=true, use UTILS_PRINTF_ENDLINE=\n by default"
  (
    params="$*"
    IFS=$'\n'
    lines=($params)
    if [[ ${NO_COLOR:-false} == true ]]; then
      for l in "${lines[@]}"; do
        printf "%s%b" "$l" "${UTILS_PRINTF_ENDLINE:-\\n}"
      done
    else
      for l in "${lines[@]}"; do
        printf "${PREFIX_COLOR}%s\e[0m%b" "$l" "${UTILS_PRINTF_ENDLINE:-\\n}"
      done
    fi
  )
}
######################################################## DEBUG #########################################################

_init_debug() {
  if [[ ${UTILS_DEBUG:-false} != false ]]; then
    set -o functrace
    trap '_debug "${BASH_SOURCE[0]}" "$LINENO"' DEBUG
    utils_debug_index=1

    if [[ ${UTILS_DEBUG} != "TRACE" ]]; then
      UTILS_DEBUG_PIPES="$(mktemp -u)-UTILS_DEBUG"
      mkfifo -m 600 "${UTILS_DEBUG_PIPES}.out" "${UTILS_DEBUG_PIPES}.in"
      utils:orange "DEBUG fifo (UTILS_DEBUG_PIPES=${UTILS_DEBUG_PIPES}) : " >&2
      utils:log "${UTILS_DEBUG_PIPES}.out" >&2
      utils:log "${UTILS_DEBUG_PIPES}.in" >&2
      set_trap_exit_debug
    fi
    if [[ ${UTILS_DEBUG} == "TERM" ]]; then
      # TODO other terminals ? auto detect term emu
      if command -v gnome-terminal >/dev/null && [[ -n $DISPLAY ]]; then
        utils:exec gnome-terminal --window -- bash -c "UTILS_DEBUG_PIPES='${UTILS_DEBUG_PIPES}' '${BASH_SOURCE}' utils:debugger" 2>/dev/null >&2
      else
        utils:red "TO DEBUG, RUN :" >&2
        echo "UTILS_DEBUG_PIPES='${UTILS_DEBUG_PIPES}' '${BASH_SOURCE}' utils:debugger" >&2
      fi
    elif [[ ${UTILS_DEBUG} == "REMOTE" ]]; then
      utils:red "TO DEBUG, RUN :" >&2
      echo "UTILS_DEBUG_PIPES='${UTILS_DEBUG_PIPES}' '${BASH_SOURCE}' utils:debugger" >&2
    elif [[ ${UTILS_DEBUG} == true ]]; then
      utils:orange "UTILS_DEBUG=true" >&2
    fi

  fi

}

_run_debug_mode_true() {
  if [[ ${PIPE_MAIN_STDERR:-true} == true ]]; then
    # colorize stderr (default)
    "$@" </dev/null 2> >(utils:pipe_error 2>&1 | tee "${UTILS_DEBUG_PIPES}.stderr" >&2) | tee "${UTILS_DEBUG_PIPES}.stdout"
  else
    "$@" </dev/null 2> >(tee "${UTILS_DEBUG_PIPES}.stderr" >&2) | tee "${UTILS_DEBUG_PIPES}.stdout"
  fi
  echo "#[DEBUG]exit 0" >"${UTILS_DEBUG_PIPES}.out" || true
}

_debug() {
  sh_source=${1##*/}
  lineno=$2
  if [[ $sh_source != "bash-utils.sh" ]]; then
    echo
    if [[ ${UTILS_DEBUG:-false} == "TRACE" ]]; then
      # TODO fix avertissement : substitution de commande : octet nul ignoré en entrée
      utils:green "$(_get_debug_trace)"
      ((utils_debug_index++))
      sleep 0.01
    elif [[ ${UTILS_DEBUG:-false} != false ]]; then
      _send_debug_trace
      _debug_command
    fi
  fi >&2
}

_send_debug_trace() {
  # TODO : define protocol
  _get_debug_trace >"${UTILS_DEBUG_PIPES}.out"
  ((utils_debug_index++))
}

_get_debug_trace() {
  printf "#[DEBUG]#%-3s ${sh_source}:%-3s → %s\n" "${utils_debug_index}" "${lineno}" "$BASH_COMMAND"
}

_debug_command() {
  local debug_command
  read -r debug_command <"${UTILS_DEBUG_PIPES}.in"
  # TODO add switch case and other command/menu : continue N times, print env, print var '$...', exec '...', add breakpoint, ...
  if [[ "$debug_command" == "continue" ]]; then
    true
  fi
}

# TODO: trap return, print exitcode and exec time ?
# TODO : fix "avertissement : substitution de commande: octet nul ignoré en entrée" if UTILS_DEBUG=TRACE ou UTILS_DEBUG=true sur certains scripts qui en appellent d'autre qui utilisent bash-utils
# TODO : mode debug dans le mm terminal : si stdin inutile
# TODO :
#  UTILS_TRY_OPEN_TERMINAL_EMU
#  sleep between
#  set breakpoint
#  next
#  next N steps
#  print env
#  print diff env
#  record env (to diff)
#  exec
#  print menu
#  print stack trace

utils:debugger() {
  utils:red "utils:debugger" >&2
  while true; do
    read -r line <"${UTILS_DEBUG_PIPES}.out"
    sleep 0.01
    utils:green "$line" >&2
    if [[ "$line" == "#[DEBUG]exit 0" ]]; then
      utils:red "→ press any key to exit" >&2
      read -s -r -n 1 cmd
      if [[ ${UTILS_DEBUG} != true ]]; then
        echo continue >"${UTILS_DEBUG_PIPES}.in"
      fi
      rm "${UTILS_DEBUG_PIPES}.out" "${UTILS_DEBUG_PIPES}.in" "${UTILS_DEBUG_PIPES}.stdout" "${UTILS_DEBUG_PIPES}.stderr" 2>/dev/null || true
      exit 0
    fi
    # TODO add switch case and other command/menu : continue N times, print env, print var '$...', exec '...', add breakpoint, ...
    utils:blue "→ press any key to continue" >&2
    read -s -r -n 1 cmd
    echo continue >"${UTILS_DEBUG_PIPES}.in"
  done
}

_cleanup_debug() {
  if [[ ${UTILS_DEBUG:-false} != false ]] && [[ ${UTILS_DEBUG:-false} != TRACE ]]; then
    trap - DEBUG
    echo "#[DEBUG]exit 0" >"${UTILS_DEBUG_PIPES}.out" || true
    UTILS_DEBUG=false
    _debug_command
    rm "${UTILS_DEBUG_PIPES}.in" "${UTILS_DEBUG_PIPES}.stdout" "${UTILS_DEBUG_PIPES}.stderr" 2>/dev/null || true
  fi
}

set_trap_exit_debug() {
  trap_exit_cmd=$(trap -p EXIT)
  trap_exit_cmd="${trap_exit_cmd% EXIT}"
  trap_exit_cmd="${trap_exit_cmd#trap -- }"
  if [[ "$trap_exit_cmd" =~ ^\'(.*)\'$ ]]; then
    trap_exit_cmd="${BASH_REMATCH[1]}"
  fi

  if [[ "$trap_exit_cmd" == "" ]]; then
    trap_exit_cmd="_trap_exit_debug"
  else
    trap_exit_cmd="$trap_exit_cmd ; _trap_exit_debug"
  fi
  trap "$trap_exit_cmd" EXIT
}
_trap_exit_debug() {
  # TODO
  echo _trap_exit_debug
}

###################################################### DEPRECATED ######################################################
# deprecated, use : utils:run main "$@"
utils:run_main() {
  utils:run main "$@"
}

########################################################################################################################

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # if the script is not being sourced
  IGNORE_UTILS_FUNCTIONS=false
  main() {
    utils:help
  }
  utils:run "$@"
fi
