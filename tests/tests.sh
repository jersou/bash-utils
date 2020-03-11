#!/usr/bin/env bash

main() {
  LOG_FILE=$(mktemp /tmp/bash-utils-tests.XXXXXX.log)
  "$GIT_TOPLEVEL/tests/lib/bats/bin/bats" -r "$GIT_TOPLEVEL/tests/bash-utils-tests" | tee "$LOG_FILE" |
    GREP_COLOR='1;31' grep --color=always -E --line-buffered '^|# skip$|^not ok' |
    GREP_COLOR='1;32' grep --color=always -E --line-buffered '^|^ok' || true
  print_summary
}

print_summary() {
  nb_ok=$(grep -c -E "^ok " "$LOG_FILE" || true)
  nb_ko=$(grep -c -E "^not ok " "$LOG_FILE" || true)
  nb_skip=$(grep -c -E "# skip$" "$LOG_FILE" || true)
  nb_ok=$((nb_ok - nb_skip))
  pc=$((100 * nb_ok / (nb_ok + nb_ko + nb_skip)))
  utils:hr
  UTILS_PRINTF_ENDLINE=" "
  utils:green " $nb_ok OK"
  utils:orange " $nb_skip SKIP"
  utils:red " $nb_ko KO"
  utils:blue " → $pc % OK"
  echo
  utils:hr
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # if the script is not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=../bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh"
  utils:run "$@"
fi
