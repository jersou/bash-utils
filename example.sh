#!/usr/bin/env bash

main() {
  declare help="print example messages and run test()"
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

test() {
  declare help="exit success if no arg"
  echo stdout message
  echo stderr message 1>&2
  echo "args=$*"
  [[ "$#" == 0 ]]
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # if the script is not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️ utils:* functions
  utils:run "$@"
fi
