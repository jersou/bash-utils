#!/usr/bin/env bash

main() {
  # shellcheck disable=SC2034
  declare help="main help"
  echo "*=$*"
  echo  echo message
  log   log message
  debug debug message
  error error message
  warn  warn message
  test
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
  source "$GIT_TOPLEVEL/bash-utils.sh"
  init
  if [[ $# == 0 ]]; then # if the script has no argument, run the main() function
    trap cleanup EXIT ERR # run cleanup() function at exit
    main "$@" 2> >(pipe_error) | pipe_log # colorize stderr and stdout
  else # if the script has at least one argument, run the function $1
    "$@"
  fi
fi

