#!/usr/bin/env bash

main() {
  utils:exec get_params_demo yy
  utils:exec get_params_demo --key
  utils:exec get_params_demo --key=aaa
  utils:exec get_params_demo --key bbb
  utils:exec get_params_demo --key ccc1 --key=ccc2 --key ccc3
  utils:exec get_params_demo -z ddd
  utils:exec get_params_demo -z=eee
  utils:exec get_params_demo -aze fff
  utils:exec get_params_demo -z=ggg1 -z ggg2
  utils:exec get_params_demo --key=hhh file1 file2 "file 3"
  utils:exec get_params_demo --key=iii -- file3 --help file4
}

get_params_demo() {
  echo "    has_param      'key'=$(utils:has_param "key" "$@" && echo true || echo false)"
  echo "    get_params     'key'=$(utils:get_params "key" "$@")"
  echo "    get_params    'key '=$(utils:get_params "key " "$@")"
  echo "    get_params      'z '=$(utils:get_params "z " "$@")"
  echo "    get_params 'key |z '=$(utils:get_params "key |z " "$@")"
  echo "    get_params      'e '=$(utils:get_params "e " "$@")"
  echo "    get_params      '--'=$(utils:get_params "--" "$@")"
  echo "    get_param      'key'=$(utils:get_param "key" "$@")"
  echo "    get_param       '--'=$(utils:get_param "--" "$@")"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️ utils:* functions
  utils:run "$@"
fi
