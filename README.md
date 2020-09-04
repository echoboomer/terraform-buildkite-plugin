# Buildkite Terraform Plugin

Allows running Terraform in a Buildkite pipeline.

**Note:** This is under development and should not be used in pipelines yet beyond testing.

## Prerequisites

The plugin assumes a few thing:

- Your Terraform code is in the root of your repository in the folder `terraform/`. At this time, another location is not supported.
- It's up to you to define what flags are used for `terraform init` by taking advantage of `init_config`. This is going to vary depending on your provider(s) and/or backend(s).
- If using a Terraform workspace, the workspace is selected before running `plan` and will also be used before running `apply`.
- If using a Terraform workspace, the plugin will also look for a `.tfvars` file in the form `WORKSPACE_NAME-terraform.tfvars`.
- If not using a Terraform workspace, the `default` workspace is used.
- At the end of the Terraform plan, the plugin automatically generates `tfplan` as-is and `tfplan.json` for a JSON formatted version of the output. This is useful if you'd like to use a plugin like [artifacts](https://github.com/buildkite-plugins/artifacts-buildkite-plugin) to move your Terraform plan between steps, which is even more useful if you've opted to make two separate steps with a dedicated `apply` step with `plan` disabled. These files are both available in the `terraform/` directory in the agent for reference. You can also run the JSON output through something like OPA.

## Example

Add the following to your `pipeline.yml`:

```yml
steps:
  - label: "terraform"
    plugins:
      - echoboomer/terraform#v0.1.4-alpha:
          init_config: "-input=false -backend-config=bucket=my_gcp_bucket -backend-config=prefix=my-prefix -backend-config=credentials=sa.json"
```

This is the only required parameter. You can pass in other options to adjust behavior:

```yml
steps:
  - label: "terraform"
    plugins:
      - echoboomer/terraform#v0.1.4-alpha:
          init_config: "-input=false -backend-config=bucket=my_gcp_bucket -backend-config=prefix=my-prefix -backend-config=credentials=sa.json"
          image: myrepo/mycustomtfimage
          version: 0.12.21
          use_workspaces: true
          workspace: development
```

## Configuration

### `apply` (Not Required, boolean)

Whether or not to run `terraform apply` on this step. The plugin only assumes `terraform plan` without this option. Set to `true` to run `terraform apply`.

### `apply_only` (Not Required, boolean)

If this option is supplied, `plan` is skipped and `apply` is forced. This is useful if creating separate steps for `plan` and `apply`. You do not need to use both this and `apply`.

### `image` (Not Required, string)

If using a custom Docker image to run `terraform`, set it here. This should only be the `repo/image` string. Set the tag in `version`. Defaults to `hashicorp/terraform`.

### `init_config` (Required, string)

A string specifying flags to pass to `terraform init`. This is required.

### `use_workspaces` (Not Required, boolean)

If you need to use Terraform workspaces in your repository, set this to `true`. You also need to pass in the name of a workspace.

### `version` (Not Required, string)

Which version of Terraform to use. Defaults to `0.13.0`. This is the tag applied to the Docker image, whether using the default of `hashicorp/terraform` or your own custom image.

### `workspace` (Not Required, string)

If setting `use_workspaces` to `true`, pass in the Terraform workspace name here.

## Developing

To run the tests:

```shell
docker-compose run --rm tests
```

## Contributing

1. Fork the repo
2. Make the changes
3. Run the tests
4. Commit and push your changes
5. Send a pull request
