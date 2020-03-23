#!/usr/bin/env bash

main() {
  declare help="main function"      # optional help
  utils:log "main function args=$*" # example
  utils:exec echo message           # example
}

cleanup() { # optional
  local exitcode=$?
  declare help="print the stack on error exit"
  if [[ $exitcode != 0 ]]; then
    utils:stack                                   # example
    utils:color bg_orange "exit code = $exitcode" # example
    return $exitcode
  fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # if the script is not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️  utils:* functions
  trap cleanup EXIT ERR TERM INT       # at exit # optional
  utils:run "$@"
fi
