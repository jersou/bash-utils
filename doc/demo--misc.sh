#!/usr/bin/env bash

main() {

  utils:exec echo 'print cmd before exec'

  utils:hr
  utils:exec utils:flock_exec lock1 flock_demo thread1 &
  sleep 0.01
  echo "parallel exec of flock_demo"
  utils:exec utils:flock_exec lock1 flock_demo thread2
  utils:hr
  utils:exec utils:stack
  utils:hr
  utils:exec utils:list_functions
  utils:hr
  utils:exec utils:help
  utils:hr
  utils:color bg_blue 'echo -e "arg1\narg2\narg3" | utils:pipe print_args' ' ← print_args = { echo "args=$*"; }'
  echo -e "arg1\narg2\narg3" | utils:pipe print_args
}

flock_demo() {
  echo "flock_demo $*"
  utils:countdown 3 # sleep 3
}

print_args() {
  echo "args=$*"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️ utils:* functions
  utils:run "$@"
fi
