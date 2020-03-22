#!/usr/bin/env bash

main() {
  declare help="print example messages"
  utils:exec echo message "$(basename "$0") $*"
  echo stdout message
  echo stderr message 1>&2 && sleep 0.01
  utils:hr
  utils:log "log message"
  utils:debug "debug message"
  utils:error "error message"
  utils:warn "warn message"
  utils:color bg_red "red message"
  utils:color bg_green "green message"
  utils:color bg_blue "blue message"
  utils:color fg_blue "blue message"
}

test_params() {
  declare help="exit success if no arg --key=value"
  echo "unk=$(utils:get_params "unk" "$@")"
  echo "key=$(utils:get_params "key" "$@")"
  utils:hr
  utils:parse_params "$@"
  utils:color bg_blue "utils_params="
  # shellcheck disable=SC2154
  for key in "${!utils_params[@]}"; do
    echo "    utils_params[$key]=${utils_params[$key]}"
  done
  [[ "${utils_params[key]}" != "value" ]] # ← utils_params[] need this call before : utils:parse_params "$@"
  # or : [[ "$(utils:get_params "key" "$@")" != "value" ]] # ← don't need "utils:parse_params" call
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️ utils:* functions
  utils:run "$@"
fi
