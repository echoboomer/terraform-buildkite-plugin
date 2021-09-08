FROM hashicorp/terraform:latest as terraform
RUN terraform version

FROM buildkite/plugin-tester
COPY . .
COPY --from=terraform /bin/terraform /bin/terraform
