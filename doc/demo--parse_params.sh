#!/usr/bin/env bash

main() {
  utils:exec parse_params_demo yy
  utils:exec parse_params_demo --key
  utils:exec parse_params_demo --key=aaa
  utils:exec parse_params_demo --key bbb
  utils:exec parse_params_demo --key ccc
  utils:exec parse_params_demo -z ddd
  utils:exec parse_params_demo -z=eee
  utils:exec parse_params_demo -aze fff
  utils:exec parse_params_demo -zzz=ggg
  utils:exec parse_params_demo --key=hhh file1 file2 "file 3"
}

parse_params_demo() {
  utils:parse_params "$@" # ← ⚠️ need to be run to set "utils_params" associative array
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
