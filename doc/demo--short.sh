#!/usr/bin/env bash
main() {
  cd "${BASH_SOURCE[0]%/*}"
  utils:color bg_purple './demo--short.sh color_print arg1 arg2'
  ./demo--short.sh color_print arg1 arg2
  utils:color bg_purple './demo--short.sh params_test --key=test file1 "file 2"'
  ./demo--short.sh params_test --key=test file1 "file 2"
  utils:color bg_purple 'UTILS_DEBUG=TRACE ./demo--short.sh get_params_test --key=val'
  UTILS_DEBUG=TRACE ./demo--short.sh get_params_test --key=val
  sleep 0.0001 # sleep to sync stderr and stdout
  utils:color bg_purple './demo--short.sh --help'
  ./demo--short.sh --help
}
color_print() {
  declare help="print example messages"
  utils:info "info message"
  utils:error "error message"
  utils:warn "warn message"
  sleep 0.0001 # sleep to sync stderr and stdout
  utils:color bg_red "red message"
  utils:color bg_green "green message"
  utils:hr
  utils:exec echo stdout message "$(basename "$0") $*"
  echo stderr message 1>&2
  sleep 0.0001 # sleep to sync stderr and stdout
  # utils:countdown 3 # = sleep 3
}
params_test() {
  declare help="check params"
  get_params_test "$@"
  _parse_params_test "$@"
}
get_params_test() {
  key=$(utils:get_params "key" "$@")
  files=$(utils:get_params "--" "$@")
  echo "key=$key, files=$files"
}
_parse_params_test() {
  utils:parse_params "$@"
  utils:color bg_blue "utils_params="
  for key in "${!utils_params[@]}"; do
    echo "    utils_params[$key]=${utils_params[$key]}"
  done
}
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️ utils:* functions
  utils:run "$@"
fi
