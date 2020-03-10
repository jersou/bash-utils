#!/usr/bin/env bash

echo ↓ ./example.sh --help
./example.sh --help
echo

echo ↓ ./example.sh
./example.sh
echo

echo ↓ PRINT_STACK_ON_ERROR=true ./example.sh test arg1 arg2
PRINT_STACK_ON_ERROR=true ./example.sh test arg1 arg2
echo

echo ↓ NO_COLOR=true ./example.sh main arg1 arg2
NO_COLOR=true ./example.sh main arg1 arg2
echo

NO_COLOR=true ./bash-utils.sh --help |
  grep -o -E " - utils:[a-zA-Z0-9_]+" |
  grep -vE "utils:help|utils:list_functions|utils:pipe_|utils:run|utils:hr|utils:msg|utils:exec|utils:countdown" |
  cut -d'-' -f2 |
  while read -r l; do
    echo "↓ ./bash-utils.sh $l msg"
    ./bash-utils.sh "$l" msg
    echo
  done

args_str='--stln -s --err=msg1 file0 --err=msg2 -err=ERROR --err msg3 -e=msg4 -e msg5 -eat=msg6 -a msg7 -t msg8 "file 0" file1 "file 2" -- file4 -file5 --err=msg9 file6 --end'
args=(--stln -s --err=msg1 file0 --err=msg2 -err=ERROR --err msg3 -e=msg4 -e msg5 -eat=msg6 -a msg7 -t msg8 "file 0" file1 "file 2" -- file4 -file5 --err=msg9 file6 --end)

params=(stln a e z unknown "err|e" "err |e " "z " "")

for param in "${params[@]}"; do
  echo
  echo "↓ ./bash-utils.sh utils:has_param \"$param\" $args_str"
  ./bash-utils.sh utils:has_param "$param" "${args[@]}"
  echo "→ exit code is $?"
  echo "↓ ./bash-utils.sh utils:get_params \"$param\" $args_str"
  ./bash-utils.sh utils:get_params "$param" "${args[@]}"
done

echo
echo ↓ ./bash-utils.sh utils:has_param '""' -a -e
./bash-utils.sh utils:has_param "" -a -e
echo "→ exit code is $?"
echo ↓ ./bash-utils.sh utils:get_params '""' -a -e
./bash-utils.sh utils:get_params "" -a -e
echo
echo

echo ↓ ./bash-utils.sh utils:countdown 5
./bash-utils.sh utils:countdown 5

echo ↓ PRINT_STACK_ON_ERROR=true TRACE=1 ./example.sh
PRINT_STACK_ON_ERROR=true TRACE=1 ./example.sh
echo