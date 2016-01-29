#!/bin/bash

# Runs all tests for the shtub library
# @param $1 [test_path=./test/*.sh] Optional specific test path to run.
main() {
  local test_path="$1"
  if [[ "$test_path" == "" ]]; then
    test_path="test/*.sh"
  fi
  shpec "$test_path"
}

main $1
