#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty
# export DOCKER_STUB_DEBUG=/dev/tty

setup() {
  export BUILDKITE_BRANCH="test"
  export BUILDKITE_PLUGIN_TERRAFORM_DEBUG="false"
  export BUILDKITE_PLUGIN_TERRAFORM_IMAGE="hashicorp/terraform"
  export BUILDKITE_PLUGIN_TERRAFORM_SKIP_APPLY_NO_DIFF="false"
  export BUILDKITE_PLUGIN_TERRAFORM_USE_WORKSPACES="false"
  export BUILDKITE_PLUGIN_TERRAFORM_VERSION="latest"
  export BUILDKITE_PLUGIN_TERRAFORM_WORKSPACE="default"
  export BUILDKITE_PLUGIN_TERRAFORM_AUTO_CREATE_WORKSPACE="true"
  export BUILDKITE_PLUGIN_TERRAFORM_WORKSPACE_METADATA_KEY=""
  export SSH_AUTH_SOCK=/var/lib/buildkite-agent/.ssh/ssh-agent.sock
}

cleanup() {
  if [[ -f "terraform/terraform.tfstate" ]]; then
    rm terraform/terraform.tfstate
  fi

  if [[ -f "terraform/tfplan" ]]; then
    rm terraform/tfplan
  fi

  if [[ -f "rm terraform/tfplan.json" ]]; then
    rm rm terraform/tfplan.json
  fi

  if [[ -f "terraform/tfplan.txt" ]]; then
    rm terraform/tfplan.txt
  fi

  if [[ -f "terraform/.terraform.lock.hcl" ]]; then
    rm terraform/.terraform.lock.hcl
  fi

  if [[ -d "terraform/.terraform" ]]; then
    rm -r terraform/.terraform
  fi
}

@test "command: terraform plan" {
  cleanup

  export BUILDKITE_PLUGIN_TERRAFORM_APPLY="false"
  export BUILDKITE_PLUGIN_TERRAFORM_APPLY_MASTER="false"
  export BUILDKITE_PLUGIN_TERRAFORM_APPLY_ONLY="false"
  export BUILDKITE_PLUGIN_TERRAFORM_NO_VALIDATE="false"
  export BUILDKITE_PLUGIN_TERRAFORM_DISABLE_SSH_KEYSCAN="true"

  stub docker \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v /plugin/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest init : terraform init" \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v /plugin/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest validate : terraform validate" \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v /plugin/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest plan -input=false -out tfplan : terraform plan -input=false -out tfplan" \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v /plugin/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest show tfplan -no-color : terraform show tfplan -no-color > tfplan.txt" \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v /plugin/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest show -json tfplan : terraform show -json tfplan > tfplan.json"
  stub buildkite-agent \
      "meta-data set tf_diff true : echo buildkite-agent metadata set"

  run $PWD/hooks/command
  run cat terraform/tfplan.txt
  assert_output --partial <<EOM

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # random_id.test will be created
  + resource "random_id" "test" {
      + b64_std     = (known after apply)
      + b64_url     = (known after apply)
      + byte_length = 8
      + dec         = (known after apply)
      + hex         = (known after apply)
      + id          = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
EOM

  unstub buildkite-agent
  unstub docker
}

@test "command: terraform apply" {
  export BUILDKITE_PLUGIN_TERRAFORM_APPLY="false"
  export BUILDKITE_PLUGIN_TERRAFORM_APPLY_MASTER="false"
  export BUILDKITE_PLUGIN_TERRAFORM_APPLY_ONLY="true"
  export BUILDKITE_PLUGIN_TERRAFORM_NO_VALIDATE="false"
  export BUILDKITE_PLUGIN_TERRAFORM_DISABLE_SSH_KEYSCAN="true"

  stub docker \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v /plugin/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest init : terraform init" \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v /plugin/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest validate : terraform validate" \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v /plugin/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest apply -input=false tfplan : terraform apply -input=false tfplan"

  run $PWD/hooks/command
  assert_output --partial <<EOM
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
EOM

  unstub docker

  cleanup
}

@test "command: terraform plan, ssh-keyscan enabled with custom location" {
  cleanup

  export BUILDKITE_PLUGIN_TERRAFORM_APPLY="false"
  export BUILDKITE_PLUGIN_TERRAFORM_APPLY_MASTER="false"
  export BUILDKITE_PLUGIN_TERRAFORM_APPLY_ONLY="false"
  export BUILDKITE_PLUGIN_TERRAFORM_NO_VALIDATE="false"
  export BUILDKITE_PLUGIN_TERRAFORM_KNOWN_HOSTS_LOCATION="tests/fixtures/known_hosts"

  stub docker \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v tests/fixtures/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest init : terraform init" \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v tests/fixtures/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest validate : terraform validate" \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v tests/fixtures/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest plan -input=false -out tfplan : terraform plan -input=false -out tfplan" \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v tests/fixtures/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest show tfplan -no-color : terraform show tfplan -no-color > tfplan.txt" \
      "run --rm -it -e SSH_AUTH_SOCK -v /var/lib/buildkite-agent/.ssh/ssh-agent.sock:/var/lib/buildkite-agent/.ssh/ssh-agent.sock -v /plugin/terraform:/svc -v tests/fixtures/known_hosts:/root/.ssh/known_hosts -w /svc hashicorp/terraform:latest show -json tfplan : terraform show -json tfplan > tfplan.json"
  stub buildkite-agent \
      "meta-data set tf_diff true : echo buildkite-agent metadata set"

  run $PWD/hooks/command
  run cat terraform/tfplan.txt
  assert_output --partial <<EOM

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # random_id.test will be created
  + resource "random_id" "test" {
      + b64_std     = (known after apply)
      + b64_url     = (known after apply)
      + byte_length = 8
      + dec         = (known after apply)
      + hex         = (known after apply)
      + id          = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
EOM

  unstub buildkite-agent
  unstub docker

  cleanup
}
