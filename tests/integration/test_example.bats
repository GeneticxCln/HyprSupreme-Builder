#!/usr/bin/env bats

@test "Test example 1" {
  run echo "Hello, World!"
  [ "$status" -eq 0 ]
  [ "$output" == "Hello, World!" ]
}

