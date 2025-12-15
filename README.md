# 🚀 Script Cài Đặt Ứng Dụng Windows Tự Động

## 📋 Mô Tả

Script PowerShell tự động hóa việc tải xuống và cài đặt các ứng dụng thiết yếu cho Windows. Đặc biệt hữu ích khi:
- Cài đặt Windows mới
- Setup máy tính cho lập trình viên Frontend
- Cần cài đặt hàng loạt ứng dụng một cách nhanh chóng

## 🎯 Danh Sách Ứng Dụng

Script tự động cài đặt các ứng dụng sau:

### Browser & Utilities
- **Google Chrome** - Trình duyệt web
- **7-Zip** - Nén/giải nén file
- **Notepad++** - Text editor nâng cao
- **Lightshot** - Chụp ảnh màn hình

### Development Tools
- **Node.js** - JavaScript runtime
- **Git** - Version control system
- **VS Code** - Code editor
- **TortoiseGit** - Git GUI client
- **Sourcetree** - Git visualization tool

### Web Development
- **XAMPP** - Apache, MySQL, PHP stack
- **FileZilla** - FTP client
- **Prepros** - CSS/JS preprocessor
- **ZOC Terminal** - Terminal emulator

### System Libraries
- **Visual C++ Redistributable** - Runtime libraries

## ⚡ Yêu Cầu Hệ Thống

- Windows 10/11 (64-bit)
- Quyền Administrator
- Kết nối Internet ổn định
- Ít nhất 5GB dung lượng trống

## 🔧 Hướng Dẫn Sử Dụng

### Bước 1: Chuẩn Bị PowerShell

**QUAN TRỌNG**: Trước khi chạy script, bạn cần cho phép thực thi script PowerShell:

#### Cách 1: Tạm thời cho phép (Khuyến nghị)
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

#### Cách 2: Cho phép vĩnh viễn (Cần cân nhắc về bảo mật)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Bước 2: Chạy Script

1. **Mở PowerShell với quyền Administrator:**
   - Nhấn `Win + X`
   - Chọn "Windows PowerShell (Admin)" hoặc "Terminal (Admin)"

2. **Di chuyển đến thư mục chứa script:**
   ```powershell
   cd "C:\đường\dẫn\đến\script"
   ```

3. **Chạy script:**
   ```powershell
   .\Install-Apps.ps1
   ```

### Bước 3: Theo Dõi Quá Trình

- Script sẽ tự động tải xuống từng ứng dụng
- Cửa sổ cài đặt sẽ hiện ra cho mỗi ứng dụng
- **Lưu ý:** Bạn cần hoàn tất quá trình cài đặt thủ công cho mỗi ứng dụng
- Script sẽ tự động tiếp tục sau khi bạn đóng cửa sổ cài đặt

### Bước 4: Restart Hệ Thống

Sau khi cài đặt xong:
- Script sẽ tự động đếm ngược **10 giây** trước khi restart
- Hãy **lưu toàn bộ công việc** của bạn
- Nhấn `Ctrl+C` nếu muốn hủy việc restart

## 📂 Cấu Trúc Hoạt Động

```
1. Kiểm tra quyền Administrator
2. Tạo thư mục tạm: C:\TempInstaller
3. Tải xuống từng ứng dụng
4. Unblock và quét file
5. Chạy installer (MSI hoặc EXE)
6. Dọn dẹp file tạm
7. Báo cáo kết quả
8. Tự động restart Windows
```

## 🛡️ Tính Năng An Toàn

- ✅ Kiểm tra quyền Administrator
- ✅ Unblock file tải về (Windows Security)
- ✅ Kiểm tra file integrity (SHA256 hash)
- ✅ Xử lý lỗi tải xuống (retry 3 lần)
- ✅ Dọn dẹp file tạm tự động
- ✅ Xóa file cứng đầu với nhiều phương pháp

## ⚠️ Lưu Ý Quan Trọng

### Trước Khi Chạy Script

1. **Tắt Antivirus tạm thời** (nếu bị chặn):
   - Windows Defender có thể chặn một số file tải về
   - Các ứng dụng đều từ nguồn chính thức

2. **Kiểm tra kết nối Internet:**
   - Đảm bảo kết nối ổn định
   - Tốc độ tốt để tải file nặng (XAMPP ~150MB)

3. **Đóng các ứng dụng đang chạy:**
   - Lưu toàn bộ công việc
   - Đóng trình duyệt, editor...

### Trong Quá Trình Chạy

- ⏳ **Không tắt PowerShell** khi đang chạy
- 🖱️ **Hoàn tất cài đặt thủ công** cho mỗi ứng dụng
- 💾 **Lưu công việc** trước khi script restart máy

## 🔍 Xử Lý Sự Cố

### Script không chạy được

**Lỗi:** `cannot be loaded because running scripts is disabled`

**Giải pháp:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

### Không có quyền Administrator

**Giải pháp:**
- Đóng PowerShell
- Nhấn chuột phải > "Run as Administrator"
- Chạy lại script

### File tải về bị lỗi

**Giải pháp:**
- Script sẽ tự động retry 3 lần
- Nếu vẫn lỗi, kiểm tra kết nối Internet
- Có thể tạm tắt antivirus

### Một số ứng dụng cài thất bại

**Giải pháp:**
- Xem báo cáo cuối cùng của script
- Cài đặt thủ công các ứng dụng bị lỗi
- Kiểm tra log lỗi trong PowerShell

## 🎨 Tùy Chỉnh Danh Sách Ứng Dụng

Để thêm/bớt ứng dụng, chỉnh sửa biến `$appList` trong script:

```powershell
$appList = @(
   @{ 
      name = "Tên Ứng Dụng"
      url = "https://link-download-truc-tiep.exe"
      requireReboot = $false 
   },
   # Thêm ứng dụng khác...
)
```

### Lưu Ý Khi Thêm URL

- ✅ **Phải là link download trực tiếp** (.exe hoặc .msi)
- ❌ **Không dùng link trang web** cần click download
- ✅ **Ưu tiên link chính thức** từ nhà phát triển
- ✅ **Kiểm tra link còn hoạt động** trước khi thêm

## 📊 Ví Dụ Output

```
============================================================
     SCRIPT CAI DAT PHAN MEM TU DONG - UI MODE
     Tong so phan mem: 14
============================================================

[1/14] Google Chrome
[OK] Tai file thanh cong! Kich thuoc: 95.2MB
[OK] Cai dat 'Google Chrome' hoan tat!

[2/14] Node.js
[OK] Tai file thanh cong! Kich thuoc: 28.5MB
[OK] Cai dat 'Node.js' hoan tat!

...

============================================================
                  BAO CAO KET QUA
============================================================
[OK] Cai moi thanh cong: 13/14
[X] That bai: 1/14

Tu dong khoi dong lai trong 10 giay...
```

## 🤝 Đóng Góp

Nếu bạn muốn:
- Thêm ứng dụng mới vào danh sách
- Báo lỗi hoặc đề xuất cải tiến
- Tối ưu hóa script

Hãy tạo Pull Request hoặc Issue!

## 📝 License

Script này được phát hành dưới MIT License - tự do sử dụng và chỉnh sửa.

## ⭐ Tips & Tricks

### Chạy Script Nhanh Hơn

Mở PowerShell và chạy một dòng lệnh:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; .\Install-Apps.ps1
```

### Kiểm Tra Execution Policy Hiện Tại

```powershell
Get-ExecutionPolicy
```

### Khôi Phục Execution Policy Mặc Định

```powershell
Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope CurrentUser
```

---

**Chúc bạn setup Windows thành công! 🎉**

*Được tạo cho các Frontend Developers - Save time, Code more!*