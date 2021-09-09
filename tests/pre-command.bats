#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

@test "pre-command: as command" {
  export BUILDKITE_PLUGIN_TERRAFORM_PRECOMMAND="echo hello from command"

  run $PWD/hooks/pre-command

  assert_success
  assert_output --partial "hello from command"
}

@test "pre-command: as file" {
  export BUILDKITE_PLUGIN_TERRAFORM_PRECOMMAND="tests/fixtures/pre-command-sample.sh"

  run $PWD/hooks/pre-command

  assert_success
  assert_output --partial "hello from file"
}
