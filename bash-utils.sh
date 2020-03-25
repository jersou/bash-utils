#!/usr/bin/env bash
# from https://github.com/jersou/bash-utils
# need bash > 4.3 (2014)

# TODO update doc
# TODO zenity debug print
# TODO see sh and README TODOs
# TODO add UTILS_LOG_LEVEL to hide debug/info/warn/error msg if the level is too high
# TODO FIXME [[ ${UTILS_STDERR_SLEEP:-true} != true ]] || sleep 0.0001 # to sync stderr and stdout

utils:init() {
  declare help="init bash options: errexit, nounset, pipefail, xtrace if TRACE==true, trap _utils_print_stack_and_exit_code if UTILS_PRINT_STACK_ON_ERROR==true"
  set -o errexit
  set -o nounset
  set -o pipefail
  set -o errtrace
  shopt -s inherit_errexit 2>/dev/null || true # workaround to hide "shopt: inherit_errexit: invalid shell option name" bash < v4.4
  if [[ ${TRACE:-false} == true ]]; then
    set -o xtrace
  fi
  if [[ ${UTILS_PRINT_STACK_ON_ERROR:-false} == true ]]; then
    trap _utils_print_stack_and_exit_code ERR TERM INT # at exit
  fi
  UTILS_ORIGIN_PWD="$(pwd)"
  _init_debug
}

utils:run() {
  declare help="run utils:init and run the main function or the function \$1, add color and use utils:pipe utils:error for stderr except if UTILS_PIPE_MAIN_STDERR!=true"
  if [[ $# == 0 ]]; then # if the script has no argument, run the main() function
    utils:run main "$@"
  elif [[ $* == --help ]]; then
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
      if [[ ${UTILS_PIPE_MAIN_STDERR:-true} == true ]]; then
        export UTILS_NO_COLOR
        "$@" 2> >(utils:pipe utils:error >&2) # colorize stderr (default)
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
  declare help="list all functions of the parent script, set UTILS_HIDE_PRIVATE_FUNCTIONS!= true to list _* functions"
  (
    if [[ -n ${UTILS_ORIGIN_PWD} ]]; then
      cd "$UTILS_ORIGIN_PWD"
    fi
    if [[ ${UTILS_IGNORE_UTILS_FUNCTIONS:-true} == true ]]; then
      bash -c ". ${BASH_SOURCE[-1]} ; typeset -F" | cut -d' ' -f3 | grep -v "^utils:"
    else
      bash -c ". ${BASH_SOURCE[-1]} ; typeset -F" | cut -d' ' -f3
    fi |
      if [[ "${UTILS_HIDE_PRIVATE_FUNCTIONS:-true}" == "true" ]]; then
        grep -v '^_'
      else
        cat
      fi
  )
}

utils:help() {
  declare help="print the help of all functions (the declare help='...')"
  [[ -z ${UTILS_HELP_HEADER:-} ]] || echo "${UTILS_HELP_HEADER:-}"
  local sh_name=$(basename "${BASH_SOURCE[-1]}")
  echo "Usage : $sh_name [--help | script_function_name [ARGS]...]"
  echo "Functions ('main' by default) : "
  set +o nounset
  for func in $(utils:list_functions); do
    help=""
    eval "$(type "${func}" | grep 'declare [h]elp=')"
    [[ -z ${help} ]] || help=" : $help"
    echo "  - ${func}${help}"
  done
  set -o nounset
  echo
  echo "Use this environment variable to activate some features :"
  echo "  - UTILS_DEBUG=TRACE to print each line (with line number) before execution"
  echo "  - UTILS_DEBUG=true same as UTILS_DEBUG=TRACE but wait for a key to be pressed (UTILS_DEBUG=TERM to open a new terminal)"
  echo "  - UTILS_PRINT_STACK_ON_ERROR=true to print the stack on error"
  echo "  - TRACE=true to enable bash option 'xtrace' "

}

utils:stack() {
  declare help="print current stack"
  utils:color bg_red "Stack:"
  local frame_number=1
  while caller ${frame_number}; do
    frame_number=$((frame_number + 1))
  done | utils:pipe utils:color bg_red
}

utils:countdown() {
  for pc in $(seq "$1" -1 1); do
    UTILS_PRINTF_ENDLINE="            \\r" utils:color bg_blue "sleep $pc sec"
    sleep 1
  done
  utils:debug "→ countdown $1 end            "
}

_add_quote_to_params() {
  local params=""
  for param in "$@"; do
    if [[ $param =~ [[:space:]] ]]; then
      params="$params \"$param\""
    else
      params="$params $param"
    fi
  done
  echo "$params"
}

utils:exec() {
  declare help="print parameter with blue background and execute parameters, print time if UTILS_PRINT_TIME=true"
  if [[ ${UTILS_PRINT_TIME:-START} == true ]]; then
    utils:color bg_blue "→ $(date +%Y-%m-%d-%H.%M.%S) → " $(_add_quote_to_params "$@")
    time "$@"
    [[ ${UTILS_STDERR_SLEEP:-true} != true ]] || sleep 0.01 # to sync stderr and stdout
    utils:color bg_blue "← $(date +%Y-%m-%d-%H.%M.%S) ← " $(_add_quote_to_params "$@")
  elif [[ ${UTILS_PRINT_TIME:-START} == START ]]; then
    utils:color bg_blue "→ $(date +%Y-%m-%d-%H.%M.%S) → " $(_add_quote_to_params "$@")
    "$@"
  else
    utils:color bg_blue "→ $*"
    "$@"
  fi
}

utils:flock_exec() {
  declare help="run <\$2 ...> command with flock (mutex) on '/var/lock/\$1.lock' file"
  utils:color bg_blue "→ flock_exec $1"
  local lock_file="/var/lock/$1.lock"
  (
    utils:color bg_orange "→ wait $lock_file"
    flock -x 9
    utils:color bg_green "→ got $lock_file"
    shift
    "$@"
  ) 9>"$lock_file" # fd > 9 doesn't work with zsh
}

_utils_print_stack_and_exit_code() {
  local exitcode=$?
  if [[ ${exitcode} != 0 ]]; then
    utils:stack
    utils:color bg_orange "exit code = $exitcode"
    exit ${exitcode}
  fi >&2
}

utils:pipe() {
  declare help="for each lines, execute parameters and append line"
  { set +x; } 2>/dev/null
  local line
  while read -r line; do
    "$@" "$line"
  done
  if [[ -n $line ]]; then
    "$@" "$line"
  fi
}

utils:hr() {
  declare help="print N horizontal line, N=1 by default, N is the first parameter"
  if [[ -n ${TERM:-} ]] && [[ -z ${COLUMNS:-} ]]; then
    COLUMNS=${COLUMNS:-$(tput cols -T "${TERM:-dumb}")}
  fi
  for ((i = 0; i < ${1:-1}; i++)); do
    printf '%*s\n' "${COLUMNS:-120}" '' | tr ' ' -
  done
}

###################################################### GET PARAMS ######################################################

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
  local utils_params_values=()
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
            utils_params_values+=("${2:-}")
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
    echo "${utils_params_values[0]:-}"
  else
    for arg in "${utils_params_values[@]}"; do
      echo "$arg"
    done
  fi
}
utils:get_param() {
  declare help="same as 'utils:get_params' but return the first result only"
  UTILS_GET_FIRST_PARAM=true utils:get_params "$@"
}
utils:has_param() {
  [[ -n $(utils:get_param "$@") ]]
}

utils:parse_params() {
  declare help="set utils_params array from \"\$@\" : --error=msg -a=123 -zer=5 opt1 'opt 2' -- file --opt3 →→ utils_params = [error]=msg ; [--]=opt1 / opt 2 / file / --opt3 ; [z]=5 ; [r]=5 ; [e]=5 ; [a]=123 (/ is \n here)"
  # for key in "${!utils_params[@]}"; do echo "utils_params[$key]=${utils_params[$key]}"; done
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
_check_no_value_param_found() {
  if [[ ${no_value_param_found} == true ]]; then
    utils:error "ERROR : param '$1' is placed after parameter that doesn't starts by a '-' : "
    utils:stack
    return 1
  fi
}
_append_params() {
  if [[ ${utils_params[$key]+true} ]]; then
    utils_params[$key]+=$'\n'"$value"
  else
    utils_params[$key]="$value"
  fi
}

##################################################### PRINT COLORS #####################################################

declare -A UTILS_COLORS=(
  [fg_black]="0;30" [fg_red]="0;31" [fg_green]="0;32" [fg_orange]="0;33" [fg_blue]="0;34" [fg_magenta]="0;35"
  [fg_cyan]="0;36" [fg_l_gray]="0;37" [fg_gray]="0;90" [fg_l_red]="0;91" [fg_l_green]="0;92" [fg_yellow]="0;93"
  [fg_l_blue]="0;94" [fg_l_magenta]="0;95" [fg_l_cyan]="0;96" [fg_white]="0;97"
  [bg_black]="1;40;97" [bg_red]="1;41;97" [bg_green]="1;42;97" [bg_orange]="1;43;30" [bg_blue]="1;44;97"
  [bg_purple]="1;45;97" [bg_cyan]="1;46;97" [bg_l_gray]="1;47;30" [bg_gray]="0;100" [bg_l_red]="0;101;30"
  [bg_l_green]="0;102;30" [bg_yellow]="0;103;30" [bg_l_blue]="0;104;30" [bg_l_magenta]="0;105"
  [bg_l_cyan]="0;106;30" [bg_white]="0;107;30"
)
declare -A UTILS_ICONS=([log]="ℹ️" [debug]="🐛" [error]="❌" [warn]="⚠️")
utils:list_colors() {
  for color in "${!UTILS_COLORS[@]}"; do
    printf "\e[%bm%s\e[0m%b%b" "${UTILS_COLORS[$color]}" "$color" "${UTILS_PRINTF_ENDLINE:-\\n}"
  done
}
utils:color() {
  declare help="print parameters 2... with \$UTILS_PREFIX_COLOR at the beginning with color \$1, except if UTILS_NO_COLOR=true, use UTILS_PRINTF_ENDLINE=\n by default"
  (
    local color params line lines date
    if ! [[ ${UTILS_COLORS[$1]+true} ]]; then
      utils:error "ERROR : Color not found !"
      [[ ${UTILS_STDERR_SLEEP:-true} != true ]] || sleep 0.01 # to sync stderr and stdout
      echo -n "colors : "
      UTILS_PRINTF_ENDLINE=" " utils:list_colors
      echo
      return 1
    fi
    color="${UTILS_COLORS[$1]}"
    shift
    params="$*"
    IFS=$'\n'
    if [[ ${UTILS_COLOR_DATE:-false} == true ]]; then
      date="$(date +%Y-%m-%d-%H.%M.%S) "
    else
      date=""
    fi
    lines=($params)
    if [[ ${UTILS_NO_COLOR:-false} == true ]]; then
      for line in "${lines[@]}"; do
        printf "%s%s%b" "$date" "$line" "${UTILS_PRINTF_ENDLINE:-\\n}"
      done
    else
      for line in "${lines[@]}"; do
        if [[ "${line}" =~ $'\033' ]]; then
          printf "%s%s%b" "$date" "$line" "${UTILS_PRINTF_ENDLINE:-\\n}"
        else
          printf "\e[%bm%s%s%s\e[0m%b" "$color" "${UTILS_PREFIX_COLOR:-}" "$date" "$line" "${UTILS_PRINTF_ENDLINE:-\\n}"
        fi
      done
    fi
  )
}
utils:log() {
  declare help=$'print parameters in green : \e[0;32mℹ️  parameters\e[0m'
  UTILS_PREFIX_COLOR="${UTILS_ICONS[log]}  " utils:color fg_green "${@}"
}
utils:info() {
  declare help=$'print parameters in green : \e[0;32mℹ️  parameters\e[0m'
  UTILS_PREFIX_COLOR="${UTILS_ICONS[log]}  " utils:color fg_green "${@}"
}
utils:debug() {
  declare help=$'print parameters in blue : \e[0;36m🐛  parameters\e[0m'
  UTILS_PREFIX_COLOR="${UTILS_ICONS[debug]} " utils:color fg_cyan "${@}"
}
utils:error() {
  declare help=$'print parameters in red to stderr : \e[0;31m❌  parameters\e[0m'
  UTILS_PREFIX_COLOR="${UTILS_ICONS[error]} " utils:color fg_red "${@}" 1>&2
  [[ ${UTILS_STDERR_SLEEP:-true} != true ]] || sleep 0.0001 # to sync stderr and stdout
}
utils:warn() {
  declare help=$'print parameters in orange to stderr : \e[0;33m️⚠️  parameters\e[0m'
  UTILS_PREFIX_COLOR="${UTILS_ICONS[warn]}  " utils:color fg_orange "${@}" 1>&2
  [[ ${UTILS_STDERR_SLEEP:-true} != true ]] || sleep 0.0001 # to sync stderr and stdout
}
######################################################## DEBUG #########################################################

_init_debug() {
  if [[ ${UTILS_DEBUG:-false} != false ]]; then
    export UTILS_DEBUG_CALL_LEVEL=$((${UTILS_DEBUG_CALL_LEVEL:-0} + 1))
    if [[ ${UTILS_DEBUG_CALL_LEVEL} -le ${UTILS_DEBUG_CALL_LEVEL_LIMIT:-2} ]]; then
      set -o functrace
      trap '_debug "${BASH_SOURCE[0]}" "$LINENO"' DEBUG
      utils_debug_index=1
      if [[ ${UTILS_DEBUG} != "TRACE" ]]; then
        UTILS_DEBUG_PIPES="$(mktemp -u)-UTILS_DEBUG"
        mkfifo -m 600 "${UTILS_DEBUG_PIPES}.out" "${UTILS_DEBUG_PIPES}.in"
        utils:color bg_orange "DEBUG fifo (UTILS_DEBUG_PIPES=${UTILS_DEBUG_PIPES}) : "
        utils:log "${UTILS_DEBUG_PIPES}.out"
        utils:log "${UTILS_DEBUG_PIPES}.in"
        _set_trap_exit_debug
      fi
      if [[ ${UTILS_DEBUG} == "TERM" ]]; then
        # TODO other terminals ? auto detect term emu
        if command -v gnome-terminal >/dev/null && [[ -n $DISPLAY ]]; then
          utils:exec gnome-terminal --window -- bash -c "UTILS_DEBUG_PIPES='${UTILS_DEBUG_PIPES}' '${BASH_SOURCE}' utils:debugger" 2>/dev/null
        else
          utils:color bg_red "TO DEBUG, RUN :"
          echo "UTILS_DEBUG_PIPES='${UTILS_DEBUG_PIPES}' '${BASH_SOURCE}' utils:debugger"
        fi
      elif [[ ${UTILS_DEBUG} == "REMOTE" ]]; then
        utils:color bg_red "TO DEBUG, RUN :"
        echo "UTILS_DEBUG_PIPES='${UTILS_DEBUG_PIPES}' '${BASH_SOURCE}' utils:debugger"
      elif [[ ${UTILS_DEBUG} == true ]]; then
        utils:color bg_orange "UTILS_DEBUG=true"
        UTILS_DEBUG_CALL_LEVEL_LIMIT=1
      fi
    fi
  fi >&2
}

_run_debug_mode_true() {
  if [[ ${UTILS_PIPE_MAIN_STDERR:-true} == true ]]; then
    # colorize stderr (default)
    "$@" </dev/null 2> >(utils:pipe utils:error 2>&1 | tee "${UTILS_DEBUG_PIPES}.stderr" >&2) | tee "${UTILS_DEBUG_PIPES}.stdout"
  else
    "$@" </dev/null 2> >(tee "${UTILS_DEBUG_PIPES}.stderr" >&2) | tee "${UTILS_DEBUG_PIPES}.stdout"
  fi
  echo "#[DEBUG]exit 0" >"${UTILS_DEBUG_PIPES}.out" || true
}

_debug() {
  sh_source=${1##*/}
  lineno=$2
  if [[ $sh_source != "bash-utils.sh" ]] && [[ $BASH_COMMAND != '[[ ${UTILS_DEBUG:-false} != TRACE ]] ← [UTILS_DEBUG="TRACE"]' ]]; then
    echo
    if [[ ${UTILS_DEBUG:-false} == "TRACE" ]]; then
      utils:pipe utils:color bg_green < <(_get_debug_trace)
      ((utils_debug_index++))
      [[ ${UTILS_STDERR_SLEEP:-true} != true ]] || sleep 0.01 # to sync stderr and stdout
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
  local param_values
  param_values="$(_get_param_values "$BASH_COMMAND" || true)"
  if [[ -n "$param_values" ]]; then
    param_values=" ← [${param_values%, }]"
  fi
  printf "#[DEBUG]%s#%-3s ${sh_source}:%-3s → %s%s\n" "$UTILS_DEBUG_CALL_LEVEL" "${utils_debug_index}" "${lineno}" "$BASH_COMMAND" "$param_values"
}
_get_param_values() {
  (
    set +o nounset
    local var
    while read var; do
      if [[ ${var} =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo -n "$var=\"${!var}\", "
      fi
    done < <(echo "$*" | grep -oE '\$\{?[a-zA-Z0-9_]+' | sed -E 's|\$\{?([a-zA-Z0-9_]+)|\1|g' | sort -u)
    set -o nounset
  )
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
# TODO : add debug commands
#         * UTILS_TRY_OPEN_TERMINAL_EMU
#         * sleep between
#         * set breakpoint
#         * next
#         * next N steps
#         * print env
#         * print diff env
#         * record env (to diff)
#         * exec
#         * print menu
#         * print stack trace

utils:debugger() {
  utils:color bg_red "utils:debugger" >&2
  local line
  while true; do
    read -r line <"${UTILS_DEBUG_PIPES}.out"
    [[ ${UTILS_STDERR_SLEEP:-true} != true ]] || sleep 0.01 # to sync stderr and stdout
    utils:color bg_green "$line"
    if [[ "$line" == "#[DEBUG]exit 0" ]]; then
      utils:color bg_red "→ press any key to exit"
      read -s -r -n 1 cmd
      if [[ ${UTILS_DEBUG} != true ]]; then
        echo continue >"${UTILS_DEBUG_PIPES}.in"
      fi
      rm "${UTILS_DEBUG_PIPES}.out" "${UTILS_DEBUG_PIPES}.in" "${UTILS_DEBUG_PIPES}.stdout" "${UTILS_DEBUG_PIPES}.stderr" 2>/dev/null || true
      exit 0
    fi
    # TODO add switch case and other command/menu : continue N times, print env, print var '$...', exec '...', add breakpoint, ...
    utils:color bg_blue "→ press any key to continue"
    read -s -r -n 1 cmd
    echo continue >"${UTILS_DEBUG_PIPES}.in"
  done >&2
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

_set_trap_exit_debug() {
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
  # TODO _trap_exit_debug
  echo TODO _trap_exit_debug
}
######################################################### WIP ##########################################################
_utils_errexit_disable_test() {
  false
  true
}
utils:try_func() { # "exit code" is 0 if true exit code is 0, else 1
  declare help='print 0 if exit code of "$@" is 0, else print 1'
  local ex=$(
    "$@" >&2 # FIXME : stdout stderr are merged to stderr
    echo 0
  )
  if [[ ${ex} == 0 ]]; then echo 0; else echo 1; fi
}
utils:exit_if_errexit_concept_is_disabled() {
  declare help='exit if errexit concept is disabled, prevent usage of function with : while, until, if, elif , && , ||,  !, and | (if pipefail is enable)'
  local errexit_disable=$(utils:try_func _utils_errexit_disable_test)
  [[ ${errexit_disable} == 0 ]] && utils:error "errexit concept is disable ! The function is used with : while, until, if, elif , && , ||,  !, or |" && exit 5 || true
}
########################################################################################################################
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # if the script is not being sourced
  UTILS_IGNORE_UTILS_FUNCTIONS=false
  if [[ $# == 0 ]]; then
    utils:help
  else
    utils:run "$@"
  fi
fi
