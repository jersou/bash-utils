#!/usr/bin/env bash

init() {
  set -o errexit
  set -o nounset
  set -o pipefail
  [[ -z ${TRACE:-} ]] || set -o xtrace
}

help() {
  # grep -o -P "^[a-zA-Z0-9\-_]+(?=\(\) \{)" "${BASH_SOURCE[1]}" | while read -r func; do
  sh_name=$(basename ${BASH_SOURCE[1]})
  [[ -z ${HELP_HEADER:-} ]] || log "${HELP_HEADER:-}"
  log "Usage : $sh_name [--help|<function name>]"
  log "Functions ('main' by default) : "
  for func in $(bash -c ". ${BASH_SOURCE[1]} ; typeset -F" | cut -d' ' -f3 | grep -v pipe_); do
    help=""
    eval "$(type "${func}" | grep 'declare [h]elp=')"
    [[ -z $help ]] || help=" : $help"
    log "  - ${func}${help}"
  done
}

print_line() {
  if [[ "${line:0:1}" == $'\033' ]]; then
    printf "%s\\n" "${line}"
  else
    ${cmd} "$line"
  fi
}

pipe_color() {
  { set +x; } 2>/dev/null
  cmd=${1}
  while read -r -e line; do
    print_line
  done
  if [[ -n $line ]]; then
    print_line
  fi
}

log() {
  printf '\e[0;32mℹ️  %s\e[0m\n' "${*}"
}
pipe_log() {
  pipe_color log
}
export -f pipe_log

debug() {
  printf '\e[0;36m🐛 %s\e[0m\n' "${*}"
}
pipe_debug() {
  pipe_color debug
}
export -f pipe_debug

error() {
  printf '\e[0;31m❌️ %s\e[0m\n' "${*}" 1>&2
}
pipe_error() {
  pipe_color error
}
export -f pipe_error

warn() {
  printf '\e[0;33m️⚠️  %s\e[0m\n' "${*}" 1>&2
}
pipe_warn() {
  pipe_color warn
}
export -f pipe_warn

# if the script is not being sourced
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
  help
fi
