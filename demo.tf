# Repository dùng để kiểm chứng cấu hình do repo IaC quản lý.
resource "github_repository" "demo" {
  name        = "repository-demo"
  description = var.demo_repository_description
  visibility  = "public"
  auto_init   = true

  has_issues   = true
  has_projects = false
  has_wiki     = false

  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  delete_branch_on_merge = true
}

resource "github_repository_ruleset" "demo" {
  name        = "protect-default-branch"
  repository  = github_repository.demo.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    pull_request {
      required_approving_review_count = 1
      dismiss_stale_reviews_on_push   = true
      allowed_merge_methods           = ["squash"]
    }
  }
}
