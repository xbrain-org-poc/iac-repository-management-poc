# Hướng dẫn chạy và tái kiểm tra

## Điều kiện

- Terraform >= 1.5 và GitHub CLI (`gh`).
- Tài khoản GitHub có quyền quản lý repo trong `xbrain-org-poc`.
- Chạy PowerShell tại thư mục chứa `main.tf` và `demo.tf`.

```powershell
gh auth status
$env:GITHUB_TOKEN = gh auth token
terraform init
terraform fmt -check
terraform validate
```

Không lưu token, state hoặc binary plan vào Git. `.gitignore` loại các file local đó.

## Clone mới và import state

Repo và ruleset đã tồn tại trên GitHub. Kiểm tra `terraform state list`, chỉ import resource chưa có trong state. Không chạy apply với state rỗng để tạo lại chúng.

```powershell
terraform import github_repository.poc iac-repository-management-poc
terraform import 'github_repository_ruleset.default_branch[0]' 'iac-repository-management-poc:24238381'
terraform import github_repository.demo repository-demo
terraform import github_repository_ruleset.demo 'repository-demo:24239438'
terraform plan
```

ID ruleset là kết quả ngày 30/09/2026. Nếu ruleset được tạo lại, lấy ID hiện tại bằng `gh api repos/xbrain-org-poc/repository-demo/rulesets` và API tương ứng của repo IaC. Chỉ có một người/state local chạy apply để tránh xung đột.

## Thay đổi cấu hình

Sửa code Terraform, xem plan trước khi apply:

```powershell
terraform plan '-out=change.tfplan'
terraform apply change.tfplan
terraform plan -detailed-exitcode
```

Plan sau apply trả exit code 0 nếu không có thay đổi, 2 nếu còn chênh lệch và 1 nếu lỗi. Plan phát hiện drift; apply mới khôi phục. Repo IaC đã có ruleset trên `main`, nên thay đổi mã và README phải đi qua branch và PR/review.
