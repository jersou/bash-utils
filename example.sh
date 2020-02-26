#!/usr/bin/env bash

main() {
  declare help="main help"
  echo "*=$*"
  echo echo message
  utils:log log message
  utils:debug debug message
  utils:error error message
  utils:warn warn message
  utils:red red message
  utils:green green message
  utils:blue blue message
  test
}

test() {
  declare help="test help"
  echo stdout message
  echo stderr message 1>&2
}

cleanup() {
  exitcode=$?
  # shellcheck disable=SC2034
  declare help="cleanup help"
  echo "→ → → cleanup"
  utils:red cleanup
  exit $exitcode
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # if the script is not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️ utils:* functions
  trap cleanup EXIT ERR                # run cleanup() at exit
  utils:run "$@"
fi
