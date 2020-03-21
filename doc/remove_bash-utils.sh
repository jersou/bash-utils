#!/usr/bin/env bash

#  grep -o -P "utils:.*(?=\(\))" ./bash-utils.sh | sort | ./remove_bash-utils.sh | grep -E "utils:[a-zA-Z0-9_]*"

main() {
  set -o errexit
  set -o nounset
  set -o pipefail
  [[ ${TRACE:-false} != true ]] || set -o xtrace

  if [[ $# -gt 0 ]]; then
    sed_opt="-E -i"
  else
    sed_opt="-E"
  fi

  # shellcheck disable=SC2016
  sed ${sed_opt} \
    -e 's/utils:debug|utils:error|utils:log|utils:warn/echo/g' \
    -e 's/utils:exec *//g' \
    -e 's/utils:hr *[0-9]*/echo "--------------------------------------------------------------------------------"/g' \
    -e 's/utils:run main *("\$@")?/set -o errexit\nset -o nounset\nset -o pipefail\nset -o errtrace\nshopt -s inherit_errexit\n[[ ${TRACE:-false} != true ]] || set -o xtrace\nmain/g' \
    -e 's/utils:init/set -o errexit\nset -o nounset\nset -o pipefail\nset -o errtrace\nshopt -s inherit_errexit\n[[ ${TRACE:-false} != true ]] || set -o xtrace/g' \
    -e 's/utils:stack/echo "Stack:"\nframe_number=1\nwhile caller $frame_number; do\n  frame_number=$((frame_number + 1))\ndone/g' \
    -e 's/utils:run *("\$@")?/if [[ $# == 0 ]]; then\n  main "$@"\nelse\n  set -o errexit\n  set -o nounset\n  set -o pipefail\n  set -o errtrace\n  shopt -s inherit_errexit\n  [[ ${TRACE:-false} != true ]] || set -o xtrace\n  "$@"\nfi/g' \
    "$@"
}

main "$@"
