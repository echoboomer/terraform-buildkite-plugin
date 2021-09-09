# Reference hashicorp/terraform image for executable.
FROM hashicorp/terraform:latest as terraform
RUN terraform version

# Build custom image for plugin testing based on the
# buildkite/plugin-tester image with the addition of
# the custom executable for terraform.
FROM buildkite/plugin-tester

# Copy over the terraform executable from the 
# hashicorp/terraform image.
COPY . .
COPY --from=terraform /bin/terraform /bin/terraform
