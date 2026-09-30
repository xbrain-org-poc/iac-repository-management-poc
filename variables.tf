variable "organization" {
  description = "GitHub organization that owns the PoC repository."
  type        = string
  default     = "xbrain-org-poc"
}

variable "demo_repository_description" {
  description = "Description of the repository used to demonstrate IaC management."
  type        = string
  default     = "PoC thành công: repository và ruleset được quản lý bằng Terraform."
}

variable "repository_name" {
  description = "Name of the repository managed by this PoC."
  type        = string
  default     = "iac-repository-management-poc"
}

variable "repository_description" {
  description = "Short description shown on GitHub."
  type        = string
  default     = "Proof of concept: manage GitHub repository settings with Terraform."
}

variable "repository_visibility" {
  description = "Repository visibility. Public enables the ruleset demo on GitHub Free."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["private", "public"], var.repository_visibility)
    error_message = "repository_visibility must be private or public."
  }
}

variable "enable_branch_ruleset" {
  description = "Enable default-branch ruleset. On GitHub Free, this requires a public repository."
  type        = bool
  default     = true
}
