
setup() {
  GIT_TOPLEVEL=$(cd "$BATS_TEST_DIRNAME" && git rev-parse --show-toplevel)
  source "$GIT_TOPLEVEL/bash-utils.sh"
}

@test "get_params error std --err=aaa --error=bbb -- ccc → bbb" {
  run utils:get_params error std --err=aaa --error=bbb -- ccc
  [[ $status = 0 ]] && [[ $output = bbb ]]
}

# TODO
