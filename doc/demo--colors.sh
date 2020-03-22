#!/usr/bin/env bash

main() {
  utils:log "log message"
  utils:info "info message"
  utils:debug "debug message"
  utils:error "error message"
  utils:warn "warn message"
  utils:hr
  utils:color bg_red "red message"
  utils:color bg_green "green message"
  utils:color bg_blue "blue message"
  utils:color fg_blue "blue message"
  utils:hr 3
  UTILS_PRINTF_ENDLINE="  " utils:list_colors && echo
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️ utils:* functions
  utils:run "$@"
fi
