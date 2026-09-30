# GitHub repository management PoC

This PoC uses Terraform to manage the private repository `iac-repository-management-poc` in the `xbrain-org-poc` GitHub organization. The organization is created manually; the repository is the IaC-managed resource.

## Managed configuration

- Repository metadata and visibility
- Issue tracker enabled; Projects and Wiki disabled
- Squash merge enabled; merge commits and rebase merge disabled
- Delete source branches after merge
- Optional default-branch ruleset requires one approving pull request review and dismisses stale approvals

The default repository is private and the sample ruleset is disabled. GitHub Free supports repository rulesets on public repositories; private repositories require a paid plan for this feature. To enable the sample ruleset on GitHub Free, set `repository_visibility = "public"` and `enable_branch_ruleset = true` in a local `terraform.tfvars` file. Only make the repository public if its contents are safe to publish.

## Prerequisites

- Terraform 1.5 or later
- GitHub CLI authenticated as an organization owner with repository administration access

The GitHub provider reads `GITHUB_TOKEN` from the environment. Do not put credentials in Terraform files or commit them.

## Manage the existing PoC repository

Terraform state is local and ignored by Git. A fresh clone therefore needs a one-time import before it can plan changes to this already existing repository. In PowerShell:

```powershell
$env:GITHUB_TOKEN = gh auth token
terraform init
terraform fmt -check
terraform validate
terraform import github_repository.poc iac-repository-management-poc
terraform plan
```

Only run `terraform import` when the current local state does not already contain `github_repository.poc`. Import records the existing GitHub repository in local state; it does not change the repository.

Review every plan before applying. After making an intentional configuration change, run `terraform plan`, then `terraform apply`, and run `terraform plan` again to confirm there are no remaining changes. Never commit Terraform state or plan files. The credential is read from the current terminal environment and is not stored in this repository.

To demonstrate repository creation instead, use a fresh working copy and set `repository_name` in a local, ignored `terraform.tfvars` file to a unique name that does not already exist in the organization. Review the plan before applying.

## Scope and follow-up

This PoC manages one private repository and can optionally manage a default-branch ruleset where the GitHub plan supports it. Team/member lifecycle is a separate workstream. For shared use, configure a protected remote Terraform backend before multiple people run applies; do not let multiple local states manage the same resource.
