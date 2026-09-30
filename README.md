# PoC quản lý GitHub Repository bằng Terraform

## Mục tiêu

Chứng minh Terraform có thể tạo repository trong GitHub Organization, quản lý thiết lập, cập nhật cấu hình và phát hiện thay đổi ngoài IaC (drift).

- Organization: [xbrain-org-poc](https://github.com/xbrain-org-poc), được tạo thủ công.
- Repo PoC: [iac-repository-management-poc](https://github.com/xbrain-org-poc/iac-repository-management-poc), được tạo bằng Terraform.
- Repo này vừa chứa mã IaC, vừa là resource Terraform quản lý.

PoC cốt lõi hoàn thành khi chứng minh được: **tạo repo → cập nhật bằng IaC → phát hiện và khôi phục drift → plan không còn thay đổi**. Một repository mẫu đủ cho phạm vi này.

## Phạm vi

PoC quản lý tên, mô tả, visibility, tính năng repository, cách merge và ruleset bảo vệ nhánh mặc định. Các kịch bản chính gồm tạo repository, cập nhật cấu hình, phát hiện drift và kiểm tra yêu cầu PR/review.

## Luồng hoạt động

```text
Khai báo Terraform → plan → review → apply → GitHub API
                                         ↓
                        Kiểm tra GitHub → plan xác nhận trạng thái
```

Terraform provider gọi GitHub API để thực hiện thay đổi. State lưu liên kết giữa resource trong code và repository đã tồn tại.

## Mã nguồn và cấu hình

| File | Vai trò |
| --- | --- |
| `main.tf` | Provider, repository và ruleset tùy chọn |
| `variables.tf` | Tên org/repo, mô tả, visibility và cờ bật ruleset |
| `outputs.tf` | Xuất URL repository |
| `.terraform.lock.hcl` | Khóa phiên bản provider đã chọn |
| `.gitignore` | Loại state, plan, config local và thư mục provider khỏi Git |

Cấu hình hiện tại:

| Thuộc tính | Giá trị |
| --- | --- |
| Visibility | Public |
| Issues | Bật |
| Wiki / Projects | Tắt |
| Squash merge | Bật |
| Merge commit / Rebase merge | Tắt |
| Xóa nhánh sau merge | Bật |
| Ruleset nhánh mặc định | Bật trong cấu hình Terraform; cần demo hành vi PR/review |

Ruleset tùy chọn yêu cầu PR, một approving review, hủy approval cũ khi có commit mới và chỉ cho squash merge.

## Điều kiện chạy

- Terraform từ phiên bản 1.5 trở lên.
- GitHub CLI (`gh`) đã đăng nhập tài khoản có quyền tạo/quản lý repo trong org.
- Chạy các lệnh PowerShell bên dưới tại thư mục chứa `main.tf`.

```powershell
gh auth status
$env:GITHUB_TOKEN = gh auth token
terraform init
terraform fmt -check
terraform validate
```

Token được truyền qua môi trường của phiên terminal. Không ghi token vào code, tfvars hoặc log. Không commit state/plan. Nếu vừa cài Terraform và terminal chưa nhận lệnh, mở terminal mới để cập nhật PATH.

## Tiếp quản repository đã có

State hiện lưu local và không nằm trong Git. Người clone mới cần import repo trước khi quản lý repo đã tồn tại.

```powershell
terraform state list
```

Nếu state chưa chứa `github_repository.poc`, import một lần:

```powershell
terraform import github_repository.poc iac-repository-management-poc
terraform plan
```

Import ghi nhận repo đã có vào state, không tạo lại repo. Không import lại nếu resource đã có trong state. PoC hiện dùng một người chạy apply; không để nhiều state local độc lập cùng quản lý repo này.

Nếu ruleset đã được triển khai nhưng chưa có trong state mới, import ruleset trước khi plan/apply. Lấy ID từ GitHub và dùng định dạng `repository:ruleset_id`:

```powershell
$rulesetId = gh api repos/xbrain-org-poc/iac-repository-management-poc/rulesets --jq '.[] | select(.name == "protect-default-branch") | .id'
terraform import 'github_repository_ruleset.default_branch[0]' "iac-repository-management-poc:$rulesetId"
terraform plan
```

Chỉ chạy import khi GitHub đã có ruleset và `terraform state list` chưa chứa resource ruleset này.

Để demo tạo repo mới, dùng working copy có state mới và đặt `repository_name` trong `terraform.tfvars` thành tên chưa tồn tại trong org. Không đổi tên trên state hiện tại chỉ để tạo repo khác, vì Terraform có thể đổi tên repo đang quản lý.

## Kịch bản chứng minh PoC

### 1. Tạo repository bằng Terraform

Với tên repo chưa tồn tại và state mới:

```powershell
terraform plan '-out=creation.tfplan'
terraform apply creation.tfplan
```

Mong đợi: plan đề xuất tạo `github_repository.poc`; apply thành công; repo xuất hiện trong đúng org với cấu hình đã khai báo.

Repo PoC hiện tại đã được tạo bằng luồng này. Không cần xóa repo để tái hiện demo tạo mới.

### 2. Cập nhật cấu hình bằng IaC

Sửa giá trị mặc định của `repository_description` trong `variables.tf` thành mô tả demo, rồi chạy:

```powershell
terraform plan '-out=update.tfplan'
terraform apply update.tfplan
terraform plan
```

Mong đợi: plan chỉ ra thay đổi mô tả; GitHub hiển thị mô tả mới; plan cuối báo `No changes`. Nếu dùng giá trị demo tạm thời, khôi phục code rồi review plan/apply để đưa repo về baseline.

### 3. Phát hiện và khôi phục drift

1. Giữ `has_issues = true` trong Terraform.
2. Trên Settings của repo PoC, tắt Issues bằng GitHub UI.
3. Chạy `terraform plan '-out=drift.tfplan'`.
4. Xác nhận plan đề xuất đổi `has_issues` từ `false` về `true`.
5. Chạy `terraform apply drift.tfplan`.
6. Kiểm tra Issues bật lại và `terraform plan` báo `No changes`.

Plan phát hiện drift trong các thuộc tính Terraform quản lý. Plan không tự khôi phục drift; cần apply sau review.

### 4. Ruleset trên repo public

Repo đã được chuyển public bằng Terraform. Cấu hình mặc định trong `variables.tf` bật ruleset để demo trên GitHub Free:

```hcl
repository_visibility = "public"
enable_branch_ruleset = true
```

Review plan, apply và kiểm tra ruleset `protect-default-branch` active trên nhánh mặc định. Demo yêu cầu PR và một approving review với reviewer khác tác giả PR. Ruleset không khai báo bypass cho owner/admin. Sau khi active, các thay đổi mã IaC và README cũng cần đi qua PR/review. Ruleset được tạo thành công chưa đủ chứng minh hành vi thực thi.

## Bằng chứng và trạng thái hiện tại

Ngày ghi nhận: **30/09/2026**. Bảng dưới ghi kết quả đã quan sát trong phiên triển khai; các kịch bản chưa chạy được ghi rõ.

| Hạng mục | Kết quả đã quan sát | Trạng thái |
| --- | --- | --- |
| Cấu hình hợp lệ | `terraform validate` thành công | Đã chạy |
| Tạo repo | Apply báo `1 added, 0 changed, 0 destroyed` | Đã chạy |
| Thiết lập repo | GitHub API trả về các giá trị đúng bảng cấu hình | Đã kiểm tra |
| Trạng thái sau apply | Plan báo `No changes` trong phiên tạo repo | Đã chạy |
| Cập nhật visibility bằng IaC | Plan đề xuất private → public; apply báo `1 changed`; API xác nhận public | Đã chạy |
| Cập nhật bằng IaC | Chưa ghi nhận kết quả demo | Chưa demo |
| Phát hiện/khôi phục drift | Chưa ghi nhận kết quả demo | Chưa demo |
| Ruleset | Bật trong cấu hình; hành vi PR/review cần kiểm chứng | Chưa demo PR/review |

Lệnh đọc cấu hình thực tế:

```powershell
gh api repos/xbrain-org-poc/iac-repository-management-poc --jq '{visibility,description,has_issues,has_wiki,has_projects,allow_squash_merge,allow_merge_commit,allow_rebase_merge,delete_branch_on_merge}'
```

Khi bàn giao, lưu log đã loại thông tin nhạy cảm hoặc ảnh chụp vào `docs/evidence/`: plan trước thay đổi, apply, kết quả trên GitHub và plan cuối. Hiện chưa có bộ bằng chứng lưu trong repo cho toàn bộ kịch bản; không coi bảng trạng thái này là thay thế cho bộ bằng chứng đó.

## Checklist hoàn thành task

### Bắt buộc cho PoC repository

- [x] Có mã Terraform quản lý repository trong đúng org.
- [x] Tạo repository thành công bằng Terraform.
- [x] Kiểm tra thiết lập GitHub khớp với cấu hình khai báo.
- [x] Có kết quả plan sau apply báo `No changes`.
- [x] Có hướng dẫn xác thực, khởi tạo và import repo đã có.
- [x] Ghi rõ phạm vi và giới hạn GitHub Free.
- [x] Cập nhật visibility bằng IaC và xác nhận public trên GitHub.
- [ ] Demo phát hiện và khôi phục drift; plan cuối không còn thay đổi.
- [ ] Lưu bằng chứng tạo/cập nhật/drift đã loại thông tin nhạy cảm.
- [ ] Chuẩn bị demo 5 phút và báo cáo kết quả cho mentor.

### Demo bảo vệ nhánh

- [x] Chọn repo public và áp dụng visibility bằng Terraform.
- [ ] Chứng minh yêu cầu PR/review hoạt động thực tế.
- [ ] Lưu bằng chứng và cập nhật trạng thái trong README.

Chỉ đánh dấu khi đã chạy và có kết quả. PoC cốt lõi không bắt buộc catalog nhiều repo, module, GitHub Actions hoặc remote state.

## Các giới hạn của GitHub Free

| Tính năng | Giới hạn ở org Free hiện tại | Hướng mở rộng |
| --- | --- | --- |
| Ruleset trên repo private | Không hỗ trợ trên repo private của org Free | Demo repo public hoặc dùng GitHub Team/Enterprise phù hợp |
| Ruleset cấp org áp dụng nhiều repo | Cần GitHub Team/Enterprise | Đưa vào thiết kế production |
| Push ruleset hạn chế đường dẫn, phần mở rộng hoặc kích thước file | Không thuộc gói Free | Dùng gói hỗ trợ phù hợp |

Nguồn chính thức: [Ruleset cấp repository và gói hỗ trợ](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets), [Ruleset cấp organization](https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization).

## Các phần chưa triển khai và roadmap

Các mục sau chưa làm trong PoC; chúng không mặc nhiên bị gói Free chặn:

- GitHub Actions chạy plan khi mở PR và apply theo quy trình review.
- Remote state có locking và kiểm soát truy cập.
- GitHub App với quyền tối thiểu cho automation.
- Catalog nhiều repo và module áp dụng cấu hình chuẩn.
- Drift detection định kỳ; template repository và metadata.
- Quản lý quyền truy cập repository.
- Chính sách archive/xóa repository có kiểm soát.

## Kịch bản trình bày với mentor

1. Giới thiệu bài toán, phạm vi và cấu hình mong muốn.
2. Chỉ ra resource Terraform và bằng chứng tạo repo.
3. Demo cập nhật mô tả: plan → review → apply → kiểm tra GitHub.
4. Demo drift với Issues: đổi UI → plan phát hiện → apply khôi phục.
5. Show plan cuối không còn thay đổi; giải thích state và giới hạn Free.
6. Trình bày kết quả PR/review của ruleset và các bước cần bổ sung để vận hành trong công ty.
