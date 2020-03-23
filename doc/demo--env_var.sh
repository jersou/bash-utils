#!/usr/bin/env bash
main() {
  cd "${BASH_SOURCE[0]%/*}"
  utils:color bg_purple './demo--env_var.sh color_print'
  ./demo--env_var.sh color_print
  sleep 0.01 # to sync stderr and stdout
  utils:hr
  utils:color bg_purple 'UTILS_NO_COLOR=true ./demo--env_var.sh color_print'
  UTILS_NO_COLOR=true ./demo--env_var.sh color_print
  sleep 0.01 # to sync stderr and stdout
  utils:hr
  #  utils:color bg_purple 'UTILS_PIPE_MAIN_STDERR=false ./demo--env_var.sh color_print'
  #  UTILS_PIPE_MAIN_STDERR=false ./demo--env_var.sh color_print
  #  sleep 0.01 # to sync stderr and stdout
  #  utils:hr
  utils:color bg_purple 'UTILS_PRINTF_ENDLINE=%%% ./demo--env_var.sh color_print'
  UTILS_PRINTF_ENDLINE=%%% ./demo--env_var.sh color_print 2>&1
  sleep 0.01 # to sync stderr and stdout
  echo
  utils:hr
  utils:color bg_purple 'UTILS_PRINT_STACK_ON_ERROR=true ./demo--env_var.sh error'
  UTILS_PRINT_STACK_ON_ERROR=true ./demo--env_var.sh error || true
  sleep 0.01 # to sync stderr and stdout
  utils:hr
  utils:color bg_purple 'UTILS_PRINT_TIME=true ./demo--env_var.sh color_print'
  UTILS_PRINT_TIME=true ./demo--env_var.sh color_print
  sleep 0.01 # to sync stderr and stdout
  utils:hr
  utils:color bg_purple 'UTILS_PRINT_TIME=false ./demo--env_var.sh color_print'
  UTILS_PRINT_TIME=false ./demo--env_var.sh color_print
  sleep 0.01 # to sync stderr and stdout
  utils:hr
  utils:color bg_purple 'UTILS_DEBUG=true ./demo--env_var.sh color_print'
  UTILS_DEBUG=true ./demo--env_var.sh color_print
  sleep 0.01 # to sync stderr and stdout
  utils:hr
  utils:color bg_purple 'UTILS_DEBUG=TERM ./demo--env_var.sh color_print'
  UTILS_DEBUG=TERM ./demo--env_var.sh color_print
  sleep 0.01 # to sync stderr and stdout
  utils:hr
}

color_print() {
  utils:exec echo stdout
  utils:info "info message"
  utils:color bg_red "red message"
  echo stdout message
  echo stderr message 1>&2
}

error() {
  return 1
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️ utils:* functions
  utils:run "$@"
fi
