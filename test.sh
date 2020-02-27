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
  grep " - utils:" |
  grep -vE "utils:help|utils:list_functions|utils:pipe_|utils:print_color|utils:print_line|utils:run|utils:hr|utils:msg" |
  cut -d'-' -f2 |
  while read -r l; do
    echo "↓ ./bash-utils.sh $l msg"
    ./bash-utils.sh "$l" msg
    echo
  done

echo ↓ TRACE=1 ./example.sh
TRACE=1 ./example.sh
echo
