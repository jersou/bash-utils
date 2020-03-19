#!/usr/bin/env bats

setup() {
  GIT_TOPLEVEL=$(cd "$BATS_TEST_DIRNAME" && git rev-parse --show-toplevel)
  source "$GIT_TOPLEVEL/bash-utils.sh"
  EOL=$'\n'
}

@test "utils:get_params error std --err=aaa --error=bbb -- ccc"
{
  run utils:get_params error std --err=aaa --error=bbb -- ccc
  [[ $status == 0 ]] && [[ $output == bbb ]]
}

@test "utils:get_params std --std --err=aaa --error=bbb -- ccc"
{
  run utils:get_params std --std --err=aaa --error=bbb -- ccc
  [[ $status == 0 ]] && [[ $output == true ]]
}

@test "utils:get_params -- std --err=aaa --error=bbb -- ccc"
{
  run utils:get_params -- std --err=aaa --error=bbb -- ccc
  [[ $status == 0 ]] && [[ ${output//$EOL//} == "std/ccc" ]]
}

@test "utils:get_params e std --err=aaa --error=bbb -e=123 -- ccc"
{
  run utils:get_params e std --err=aaa --error=bbb -e=123 -- ccc
  [[ $status == 0 ]] && [[ ${output//$EOL//} == "123" ]]
}

@test "utils:get_params e std --err=aaa --error=bbb -- ccc -e=123"
{
  run utils:get_params e std --err=aaa --error=bbb -- ccc -e=123
  [[ $status == 0 ]] && [[ ${output//$EOL//} == "" ]]
}

@test "utils:get_params 'e ' std --err=aaa --error=bbb -- ccc -e=123"
{
  run utils:get_params 'e ' std --err=aaa --error=bbb -- ccc -e=123
  [[ $status == 0 ]] && [[ ${output//$EOL//} == "" ]]
}

@test "utils:get_params 'e ' std --err=aaa --error=bbb -e 123 -- ccc"
{
  run utils:get_params 'e ' std --err=aaa --error=bbb -e 123 -- ccc
  [[ $status == 0 ]] && [[ ${output//$EOL//} == "123" ]]
}

@test "utils:get_params 'e' std --err=aaa --error=bbb -e 123 -- ccc"
{
  run utils:get_params 'e' std --err=aaa --error=bbb -e 123 -- ccc
  [[ $status == 0 ]] && [[ ${output//$EOL//} == "true" ]]
}

@test "utils:get_params 'e|err' std --err=aaa --error=bbb -e=123 -- ccc"
{
  run utils:get_params 'e|err' std --err=aaa --error=bbb -e=123 -- ccc
  [[ $status == 0 ]] && [[ ${output//$EOL//} == "aaa/123" ]]
}

@test "utils:get_params 'e|err' std --err=aaa --error=bbb -e 123 -- ccc"
{
  run utils:get_params 'e |err' std --err=aaa --error=bbb -e 123 -- ccc
  [[ $status == 0 ]] && [[ ${output//$EOL//} == "aaa/123" ]]
}

# TODO tests
