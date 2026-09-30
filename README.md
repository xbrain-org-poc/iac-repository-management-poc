# GitHub repository management PoC

This PoC uses Terraform to create and manage a private repository in the `xbrain-org-poc` GitHub organization.

## Managed configuration

- Repository metadata and visibility
- Issue tracker enabled; Projects and Wiki disabled
- Squash merge enabled; merge commits and rebase merge disabled
- Delete source branches after merge
- Optional default-branch ruleset requires one approving pull request review and dismisses stale approvals

The organization itself is created manually. Terraform manages repository resources inside it.

The default repository is private. GitHub Free supports repository rulesets on public repositories; private repositories require a paid plan for this feature. To enable the sample ruleset on GitHub Free, set `repository_visibility = "public"` and `enable_branch_ruleset = true` in a local `terraform.tfvars` file. Only make the repository public if its contents are safe to publish.

## Prerequisites

- Terraform 1.5 or later
- GitHub CLI authenticated as an organization owner with repository administration access

The GitHub provider reads `GITHUB_TOKEN` from the environment. Do not put credentials in Terraform files or commit them.

## Run

In PowerShell, set the provider credential for the current terminal session and review the plan before applying:

```powershell
$env:GITHUB_TOKEN = gh auth token
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Review the plan and type `yes` when Terraform asks to apply it. The provider credential is not stored in this repository. Terraform state is local and ignored by Git; do not commit it.

To verify the configuration is converged, run `terraform plan` again after apply. It should report no changes.

## Scope and follow-up

This PoC manages one private repository and its default-branch protection. Team/member lifecycle is a separate workstream. For shared use, configure a protected remote Terraform backend before multiple people run applies.
