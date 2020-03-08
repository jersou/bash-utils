#!/usr/bin/env bash

echo ↓ ./example.sh --help
./example.sh --help
echo

echo ↓ ./example.sh
./example.sh
echo

echo ↓ ./example.sh test arg1 arg2
./example.sh test arg1 arg2
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

echo ↓ ./bash-utils.sh utils:countdown 5
./bash-utils.sh utils:countdown 5

echo ↓ PRINT_STACK_ON_ERROR=true TRACE=1 ./example.sh
PRINT_STACK_ON_ERROR=true TRACE=1 ./example.sh
echo
