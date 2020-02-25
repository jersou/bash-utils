#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ↓ ./example.sh --help
./example.sh --help
echo 

echo ↓ ./example.sh
./example.sh
echo 

echo ↓ ./example.sh main arg1 arg2
./example.sh main arg1 arg2
echo 

echo ↓ ./example.sh test arg1 arg2
./example.sh test arg1 arg2
echo 

NO_COLOR=true ./bash-utils.sh --help |
  grep utils: |
  grep -vE "utils:help|utils:list_functions|utils:pipe_|utils:print_color|print_line|utils:run" |
  cut -d' ' -f2 |
  while read l; do
    echo "↓ ./bash-utils.sh $l msg"
    ./bash-utils.sh $l msg
    echo
  done
