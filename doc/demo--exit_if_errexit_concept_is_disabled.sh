#!/usr/bin/env bash
main() {
  echo '$ func_ok_with_check'
  func_ok_with_check | cat
  echo '$ func_ok_with_check || echo "⇨ unreachable... because of exit_if_errexit_concept_is_disabled"'
  func_ok_with_check || echo "⇨ unreachable... because of exit_if_errexit_concept_is_disabled"
  echo "  ⇨ unreachable..."
}

func_ok_with_check() {
  echo "  ✅ func_with_check begin ✅"
  utils:exit_if_errexit_concept_is_disabled # prevent func_ok_with_check usage with : while, until, if, elif , && , ||,  !, and | (if pipefail is enable)
  echo "  ✅ func_with_check end ✅"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then # not being sourced
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
  # shellcheck source=./bash-utils.sh
  source "$GIT_TOPLEVEL/bash-utils.sh" # ←⚠️ utils:* functions
  utils:run "$@"
fi
