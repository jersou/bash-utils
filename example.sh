#!/usr/bin/env bash

main() {
  declare help="main help"
  echo "*=$*"
  echo echo message
  utils:log log message
  utils:debug debug message
  utils:error error message
  utils:warn warn message
  test "$@"
}

test() {
  declare help="test help"
  echo "*=$*"
  echo stdout message
  echo stderr message 1>&2
}

cleanup() {
  exitcode=$?
  # shellcheck disable=SC2034
  declare help="cleanup help"
  echo cleanup
  exit $exitcode
}

# if the script is not sourced
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️
  utils:run "$@"
fi
