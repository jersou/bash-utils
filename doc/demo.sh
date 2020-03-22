#!/usr/bin/env bash

cd "${BASH_SOURCE[0]%/*}" || exit 1

echo '↓ ./example.sh --help'
./example.sh --help
echo

echo '↓ ./example.sh'
./example.sh
echo

echo '↓ UTILS_PRINT_STACK_ON_ERROR=true ./example.sh test_params --par=v1 --key=value --par="v 1.1" f1 f2'
UTILS_PRINT_STACK_ON_ERROR=true ./example.sh test_params --par=v1 --key=value --par="v 1.1" f1 f2
echo

echo '↓ UTILS_NO_COLOR=true ./example.sh main arg1 arg2'
UTILS_NO_COLOR=true ./example.sh main arg1 arg2
echo

cd ".." || exit 1

UTILS_NO_COLOR=true ./bash-utils.sh --help |
  grep -o -E " - utils:[a-zA-Z0-9_]+" |
  grep -vE "utils:help|utils:list_functions|utils:run|utils:hr|utils:exec|utils:countdown|utils:parse_params|utils:get_params|utils:get_param|utils:has_param|utils:debugger|utils:pipe" |
  cut -d'-' -f2 |
  while read -r l; do
    ./bash-utils.sh utils:hr 2 | ./bash-utils.sh utils:pipe utils:color bg_purple
    echo "↓ ./bash-utils.sh $l msg"
    ./bash-utils.sh "$l" msg
    echo
  done

args_str='--stln -s --err=msg1 file0 --err=msg2 -err=ERROR --err msg3 -e=msg4 -e msg5 -eat=msg6 -a msg7 -t msg8 "file 0" file1 "file 2" -- file4 -file5 --err=msg9 file6 --end'
args=(--stln -s --err=msg1 file0 --err=msg2 -err=ERROR --err msg3 -e=msg4 -e msg5 -eat=msg6 -a msg7 -t msg8 "file 0" file1 "file 2" -- file4 -file5 --err=msg9 file6 --end)

params=(stln a e z unknown "err|e" "err |e " "z " "--")

for param in "${params[@]}"; do
  echo
  echo "↓ ./bash-utils.sh utils:has_param \"$param\" $args_str"
  ./bash-utils.sh utils:has_param "$param" "${args[@]}"
  echo "→ exit code is $?"
  echo "↓ ./bash-utils.sh utils:get_params \"$param\" $args_str"
  ./bash-utils.sh utils:get_params "$param" "${args[@]}"
done

echo
echo "↓ ./bash-utils.sh utils:has_param '--' -a -e"
./bash-utils.sh utils:has_param '--' -a -e
echo "→ exit code is $?"
echo "↓ ./bash-utils.sh utils:get_params '--' -a -e"
./bash-utils.sh utils:get_params '--' -a -e
echo
echo

echo "↓ ./bash-utils.sh utils:countdown 3"
./bash-utils.sh utils:countdown 3

cd "doc" || exit 1
echo "↓ UTILS_PRINT_STACK_ON_ERROR=true TRACE=true ./example.sh"
UTILS_PRINT_STACK_ON_ERROR=true TRACE=true ./example.sh
echo
sleep 0.2

echo "↓ UTILS_TRACE=true ./example.sh"
UTILS_TRACE=true ./example.sh
sleep 0.01
./bash-utils.sh utils:hr
echo "↓ UTILS_DEBUG=TRACE ./example.sh"
UTILS_DEBUG=TRACE ./example.sh
./bash-utils.sh utils:hr

echo "↓ ./demo--colors.sh"
./demo--colors.sh
./bash-utils.sh utils:hr

echo "↓ ./demo--get_params.sh"
./demo--get_params.sh
./bash-utils.sh utils:hr

echo "↓ ./demo--parse_params.sh"
./demo--parse_params.sh
./bash-utils.sh utils:hr

echo "↓ ./demo--misc.sh"
./demo--misc.sh
echo
