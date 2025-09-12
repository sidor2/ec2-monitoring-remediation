# Terraform Project Template

This repository serves as a template for Terraform projects. It follows best practices such as modular design, variable separation, output exposure, and remote state management.

## Best Practices Incorporated
- **Modularity**: Use modules for reusable components.
- **File Separation**: Dedicated files for variables, outputs, providers, etc.
- **Naming**: Use snake_case for resources and variables.
- **Variables**: Include types, defaults (where appropriate), and descriptions.
- **Outputs**: Expose key resource details.
- **State Management**: Configure a remote backend to avoid local state issues.
- **Environments**: Use Terraform workspaces (e.g., `terraform workspace new dev`) instead of separate directories.
- **Validation**: Run `terraform fmt` and `terraform validate` regularly.
- **Security**: Never commit sensitive data; use .tfvars for vars and ignore them.
- **Versioning**: Pin provider versions for consistency.

## Getting Started
1. Generate a new repo from this template.
2. Clone it locally.
3. Rename `terraform.tfvars.example` to `terraform.tfvars` and fill in values.
4. Run `terraform init` to initialize.
5. Create a workspace: `terraform workspace new <env>`.
6. Run `terraform plan` and `terraform apply`.

## Example Usage
This template includes an example module for an AWS EC2 instance. Customize `main.tf` to call your own modules.

## Inputs
See `variables.tf` for required/optional variables.

## Outputs
See `outputs.tf` for exposed values.

Generated with terraform-docs: terraform-docs markdown table --output-file README.md --output-mode inject .