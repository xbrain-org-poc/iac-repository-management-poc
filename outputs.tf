output "repository_url" {
  description = "URL of the managed GitHub repository."
  value       = github_repository.poc.html_url
}

output "demo_repository_url" {
  description = "URL of the separate demo repository managed by Terraform."
  value       = github_repository.demo.html_url
}
