# ============================================================
# SCRIPT CAI DAT PHAN MEM TU DONG - UI MODE
# Mo ta: Tu dong tai file va hien thi UI cai dat
# ============================================================

# Kiem tra quyen Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "CANH BAO: Script can chay voi quyen Administrator!" -ForegroundColor Red
    Write-Host "Hay mo PowerShell as Administrator va chay lai script." -ForegroundColor Yellow
    pause
    exit
}

# Cau hinh toan cuc
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Bien toan cuc
$script:downloadFolder = "C:\TempInstaller"
$script:filesToCleanup = @()

# ============================================================
# DANH SACH PHAN MEM
# ============================================================
$appList = @(
   #@{ name = "Google Chrome"; url = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"; requireReboot = $false },
   #@{ name = "7-Zip"; url = "https://www.7-zip.org/a/7z2501-x64.exe"; requireReboot = $false },
   #@{ name = "Notepad++"; url = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.8.9/npp.8.8.9.Installer.x64.msi"; requireReboot = $false },
   #@{ name = "Node.js"; url = "https://nodejs.org/dist/v24.12.0/node-v24.12.0-x64.msi"; requireReboot = $false },
   #@{ name = "Git"; url = "https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/Git-2.52.0-64-bit.exe"; requireReboot = $false },
   #@{ name = "vc_redist"; url = "https://aka.ms/vs/17/release/vc_redist.x64.exe"; requireReboot = $false },
   #@{ name = "TortoiseGit"; url = "https://download.tortoisegit.org/tgit/2.18.0.0/TortoiseGit-2.18.0.1-64bit.msi"; requireReboot = $false },
   @{ name = "VS Code"; url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"; requireReboot = $false }
   #@{ name = "Sourcetree"; url = "https://product-downloads.atlassian.com/software/sourcetree/windows/ga/SourceTreeSetup-3.4.27.exe"; requireReboot = $false },
   #@{ name = "Lightshot"; url = "https://app.prntscr.com/build/setup-lightshot.exe"; requireReboot = $false },
   #@{ name = "Prepros"; url = "https://prepros.io/downloads/stable/windows"; requireReboot = $false },
   #@{ name = "FileZilla"; url = "https://download.filezilla-project.org/client/FileZilla_3.69.5_win64_sponsored2-setup.exe"; requireReboot = $false },
   #@{ name = "ZOC Terminal"; url = "https://www.emtec.com/downloads/zoc/zoc9021_x64.exe"; requireReboot = $false },
   #@{ name = "XAMPP"; url = "https://zenlayer.dl.sourceforge.net/project/xampp/XAMPP%20Windows/8.0.30/xampp-windows-x64-8.0.30-0-VS16-installer.exe?viasf=1"; requireReboot = $false }
)

# ============================================================
# HAM TIEN ICH
# ============================================================

function Write-Status {
    param(
        [string]$message,
        [string]$type = "info"
    )
    
    switch ($type) {
        "success" { Write-Host "[OK] $message" -ForegroundColor Green }
        "error"   { Write-Host "[X] $message" -ForegroundColor Red }
        "warning" { Write-Host "[!] $message" -ForegroundColor Yellow }
        "info"    { Write-Host "[i] $message" -ForegroundColor Cyan }
        default   { Write-Host "$message" -ForegroundColor Gray }
    }
}

function Write-Section {
    param([string]$title)
    
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
}

function Get-FileExtension {
    param([string]$url)
    
    if ($url -match "\.(msi|exe)$") {
        return $matches[0]
    }
    return ".exe"
}

function Get-SafeFileName {
    param(
        [string]$name,
        [string]$extension
    )
    
    $safeName = $name -replace '[^\w\-]', ''
    return "${safeName}${extension}"
}

# ============================================================
# HAM XOA FILE CUNG DAU
# ============================================================
function Remove-FileForce {
    param(
        [string]$filePath,
        [int]$maxAttempts = 5
    )
    
    if (-not (Test-Path $filePath)) {
        return $true
    }
    
    Write-Status "Dang xoa file: $(Split-Path $filePath -Leaf)"
    
    for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
            Remove-Item $filePath -Force -ErrorAction Stop
            Write-Status "Da xoa file thanh cong" "success"
            return $true
        } 
        catch {
            if ($i -lt $maxAttempts) {
                # Thu unlock file
                try {
                    [System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::Normal)
                    Remove-Item $filePath -Force -ErrorAction Stop
                    Write-Status "Da unlock va xoa file" "success"
                    return $true
                } catch {
                    # Thu dung cmd
                    cmd /c "del /F /Q `"$filePath`"" 2>$null
                    if (-not (Test-Path $filePath)) {
                        Write-Status "Da xoa file bang cmd" "success"
                        return $true
                    }
                }
                
                Start-Sleep -Seconds 1
            }
        }
    }
    
    # Doi ten file neu khong xoa duoc
    try {
        $newName = "${filePath}.delete_me_$(Get-Random)"
        Rename-Item $filePath -NewName $newName -Force -ErrorAction Stop
        Write-Status "Da doi ten file de xoa sau" "warning"
        return $true
    } catch {
        Write-Status "Khong the xoa file sau $maxAttempts lan thu" "warning"
        return $false
    }
}

# ============================================================
# HAM TAI FILE
# ============================================================
function Get-FileFromUrl {
    param(
        [string]$url,
        [string]$destination,
        [int]$maxAttempts = 3
    )
    
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        Write-Status "Dang thu tai file (Lan $attempt/$maxAttempts)..." "info"
        
        try {
            # Xoa file cu
            if (Test-Path $destination) {
                Remove-FileForce -filePath $destination | Out-Null
                Start-Sleep -Milliseconds 500
            }
            
            # Tai file bang WebClient
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
            $webClient.Headers.Add("Accept", "*/*")
            $webClient.DownloadFile($url, $destination)
            $webClient.Dispose()
            
            # Kiem tra file
            if (-not (Test-Path $destination)) {
                throw "File khong duoc tao sau khi tai xuong"
            }
            
            $fileInfo = Get-Item $destination
            if ($fileInfo.Length -eq 0) {
                throw "File tai ve co dung luong 0 bytes"
            }
            
            $fileSizeMB = [math]::Round($fileInfo.Length/1MB, 2)
            Write-Status "Tai file thanh cong! Kich thuoc: ${fileSizeMB}MB" "success"
            
            if ($fileSizeMB -lt 1) {
                Write-Status "File nho hon 1MB - Co the la stub installer" "warning"
            }
            
            return $true
            
        } catch {
            Write-Status "Loi o lan ${attempt}: $($_.Exception.Message)" "error"
            
            if ($attempt -ge $maxAttempts) {
                Write-Status "Da het so lan thu tai" "error"
                return $false
            }
            
            Start-Sleep -Seconds 5
        }
    }
    
    return $false
}

# ============================================================
# HAM UNBLOCK FILE
# ============================================================
function Unblock-FileSecure {
    param([string]$filePath)
    
    Write-Status "Dang unblock file..."
    
    try {
        Unblock-File -Path $filePath -ErrorAction Stop
        Write-Status "File da duoc unblock" "success"
        return $true
    } catch {
        # Thu xoa Zone.Identifier
        try {
            Remove-Item -Path "${filePath}:Zone.Identifier" -Force -ErrorAction SilentlyContinue
            Write-Status "Da xoa Zone.Identifier" "success"
            return $true
        } catch {
            Write-Status "Khong the unblock file" "warning"
            return $false
        }
    }
}

# ============================================================
# HAM DOI ANTIVIRUS SCAN
# ============================================================
function Wait-FileReady {
    param(
        [string]$filePath,
        [int]$timeoutSeconds = 30
    )
    
    Write-Status "Dang cho antivirus scan..."
    
    $endTime = (Get-Date).AddSeconds($timeoutSeconds)
    
    while ((Get-Date) -lt $endTime) {
        try {
            $stream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
            $stream.Close()
            Write-Status "File da san sang" "success"
            return $true
        } catch {
            Start-Sleep -Seconds 1
        }
    }
    
    Write-Status "Timeout cho file san sang" "warning"
    return $false
}

# ============================================================
# HAM KIEM TRA FILE INTEGRITY
# ============================================================
function Test-FileIntegrity {
    param([string]$filePath)
    
    Write-Host "`n[Kiem tra file integrity]" -ForegroundColor Magenta
    
    try {
        $hash = Get-FileHash -Path $filePath -Algorithm SHA256 -ErrorAction Stop
        Write-Status "File hash: $($hash.Hash.Substring(0,16))..." "success"
        
        # Thu doc file
        $testBytes = [System.IO.File]::ReadAllBytes($filePath) | Select-Object -First 1024
        Write-Status "File co the doc duoc (tested $($testBytes.Count) bytes)" "success"
        
        return $true
        
    } catch {
        Write-Status "CANH BAO: Khong the doc file!" "error"
        Write-Status "Chi tiet: $($_.Exception.Message)" "error"
        
        Write-Host "`nFile co the bi corrupt. Thu cai dat khong? (Y/N): " -NoNewline -ForegroundColor Yellow
        $choice = Read-Host
        
        return ($choice -eq "Y" -or $choice -eq "y")
    }
}

# ============================================================
# HAM CHAY INSTALLER
# ============================================================
function Start-Installer {
    param(
        [string]$filePath,
        [string]$extension
    )
    
    Write-Section "DANG KHOI CHAY INSTALLER..."
    Write-Host "VUI LONG HOAN TAT CAI DAT BANG TAY" -ForegroundColor Yellow
    Write-Host "Script se tu dong tiep tuc sau khi ban dong cua so cai dat" -ForegroundColor Yellow
    
    try {
        if ($extension -eq ".msi") {
            Write-Status "Che do: MSI Installer" "info"
            
            try {
                Start-Process msiexec.exe -ArgumentList "/i `"$filePath`"" -Wait -ErrorAction Stop
                return $true
            } catch {
                Write-Status "Start-Process that bai, thu cmd.exe..." "warning"
                Start-Process cmd.exe -ArgumentList "/c msiexec.exe /i `"$filePath`"" -Wait -ErrorAction Stop
                return $true
            }
            
        } elseif ($extension -eq ".exe") {
            Write-Status "Che do: EXE Installer" "info"
            
            try {
                $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                $processInfo.FileName = $filePath
                $processInfo.UseShellExecute = $true
                $processInfo.Verb = "runas"
                
                $process = [System.Diagnostics.Process]::Start($processInfo)
                $process.WaitForExit()
                return $true
                
            } catch {
                Write-Status "ProcessStartInfo that bai, thu cmd.exe..." "warning"
                Start-Process cmd.exe -ArgumentList "/c `"$filePath`"" -Wait -Verb RunAs -ErrorAction Stop
                return $true
            }
            
        } else {
            Write-Status "Khong ho tro dinh dang $extension" "error"
            return $false
        }
        
    } catch {
        Write-Status "LOI KHI CHAY INSTALLER: $($_.Exception.Message)" "error"
        
        # Thu mo bang Explorer
        Write-Status "Thu mo file bang Explorer..." "warning"
        try {
            Start-Process explorer.exe -ArgumentList "/select,`"$filePath`"" -ErrorAction Stop
            Write-Status "Da mo Explorer. Vui long click dup vao file de cai thu cong." "info"
            Write-Host "Nhan Enter khi hoan tat cai dat..." -NoNewline
            Read-Host
            return $true
        } catch {
            Write-Status "Khong the mo Explorer" "error"
            return $false
        }
    }
}

# ============================================================
# HAM CAI DAT CHINH
# ============================================================
function Install-Application {
    param(
        [string]$name,
        [string]$url
    )
    
    Write-Section "Dang xu ly: $name"
    
    try {
        # Tao folder
        if (-not (Test-Path $script:downloadFolder)) {
            New-Item -ItemType Directory -Path $script:downloadFolder -Force | Out-Null
        }
        
        # Chuan bi path
        $extension = Get-FileExtension -url $url
        $fileName = Get-SafeFileName -name $name -extension $extension
        $tempFile = Join-Path $script:downloadFolder $fileName
        
        Write-Status "Dang tai file tu: $url" "info"
        Write-Status "Vi tri luu tam: $tempFile" "info"
        
        # Tai file
        if (-not (Get-FileFromUrl -url $url -destination $tempFile)) {
            return $false
        }
        
        # Unblock file
        Unblock-FileSecure -filePath $tempFile | Out-Null
        
        # Cho file san sang
        Wait-FileReady -filePath $tempFile | Out-Null
        
        # Kiem tra integrity
        if (-not (Test-FileIntegrity -filePath $tempFile)) {
            Remove-FileForce -filePath $tempFile | Out-Null
            return $false
        }
        
        # Chay installer
        $installSuccess = Start-Installer -filePath $tempFile -extension $extension
        
        if ($installSuccess) {
            Write-Status "Cai dat '$name' hoan tat!" "success"
        } else {
            Write-Status "Khong the cai dat '$name'" "error"
        }
        
        # Cho truoc khi xoa
        Write-Status "Dang cho de xoa file tam..."
        Start-Sleep -Seconds 3
        
        # Xoa file
        if (-not (Remove-FileForce -filePath $tempFile)) {
            Write-Status "File chua xoa duoc: $tempFile" "warning"
            $script:filesToCleanup += $tempFile
        }
        
        return $installSuccess
        
    } catch {
        Write-Status "Loi tong the: $($_.Exception.Message)" "error"
        
        if (Test-Path $tempFile) {
            Remove-FileForce -filePath $tempFile | Out-Null
        }
        
        return $false
    }
}

# ============================================================
# HAM DON DEP CUOI CUNG
# ============================================================
function Invoke-FinalCleanup {
    # Thu xoa cac file con sot
    if ($script:filesToCleanup.Count -gt 0) {
        Write-Section "Dang don dep cac file con sot..."
        
        foreach ($file in $script:filesToCleanup) {
            Write-Status "Thu xoa: $file"
            Remove-FileForce -filePath $file | Out-Null
        }
    }
    
    # Xoa folder tam
    if (Test-Path $script:downloadFolder) {
        $remainingFiles = Get-ChildItem $script:downloadFolder -File -ErrorAction SilentlyContinue
        
        if ($remainingFiles.Count -eq 0) {
            try {
                Remove-Item $script:downloadFolder -Recurse -Force -ErrorAction Stop
                Write-Status "Da xoa folder $script:downloadFolder" "success"
            } catch {
                Write-Status "Khong the xoa folder (co the van dang duoc su dung)" "warning"
            }
        } else {
            Write-Status "Con $($remainingFiles.Count) file chua xoa duoc trong $script:downloadFolder" "warning"
            Write-Status "Ban co the xoa thu cong sau."
        }
    }
}

# ============================================================
# HAM XU LY RESTART
# ============================================================
function Invoke-RestartPrompt {
    param([array]$rebootApps)
    
    Write-Section "CAN KHOI DONG LAI WINDOWS"
    
    Write-Host "`nCac phan mem sau yeu cau khoi dong lai:" -ForegroundColor Yellow
    foreach ($app in $rebootApps) {
        Write-Host "  - $app" -ForegroundColor Cyan
    }
    
    Write-Host "`n============================================" -ForegroundColor Yellow
    Write-Host "Ban muon khoi dong lai ngay bay gio?" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "[Y] Co - Khoi dong lai ngay" -ForegroundColor Green
    Write-Host "[N] Khong - Khoi dong lai sau (mac dinh)" -ForegroundColor Gray
    Write-Host "[C] Huy - Khong khoi dong lai" -ForegroundColor Red
    
    $countdown = 10
    $choice = $null
    
    while ($countdown -gt 0 -and $choice -eq $null) {
        $message = "Tu dong chon [N] sau $countdown giay..."
        $padding = ' ' * [Math]::Max(0, 60 - $message.Length)
        Write-Host "`r${message}${padding}" -NoNewline -ForegroundColor Gray
        
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            $choice = $key.KeyChar.ToString().ToUpper()
        }
        
        Start-Sleep -Seconds 1
        $countdown--
    }
    
    Write-Host "`r$(' ' * 60)`r" -NoNewline
    
    if ($null -eq $choice) {
        $choice = "N"
    }
    
    switch ($choice) {
        "Y" {
            Write-Status "Dang khoi dong lai trong 5 giay..." "warning"
            Write-Host "Hay luu cong viec cua ban!" -ForegroundColor Red
            Start-Sleep -Seconds 5
            Restart-Computer -Force
        }
        "N" {
            Write-Status "Ban da chon khoi dong lai sau" "success"
            Write-Status "Luu y: Hay khoi dong lai Windows de cac phan mem hoat dong dung!" "warning"
        }
        "C" {
            Write-Status "Da huy khoi dong lai" "success"
            Write-Status "Canh bao: Mot so phan mem co the khong hoat dong dung!" "warning"
        }
    }
}

# ============================================================
# HÀM XỬ LÝ RESTART TỰ ĐỘNG (AUTO RESTART FUNCTION)
# ============================================================
function Invoke-AutoRestart {
    param (
        # Thay đổi tham số, không cần Mandatory=$true nữa
        [string[]]$rebootApps = @()
    )

    Write-Host "`n============================================" -ForegroundColor Yellow
    Write-Host "TỰ ĐỘNG RESTART WINDOWS SAU 10 GIÂY" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
    
    # Hiển thị danh sách các app yêu cầu restart (nếu có)
    if ($rebootApps.Count -gt 0) {
        Write-Host "Các phần mềm sau yêu cầu khởi động lại: $($rebootApps -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host "Không có ứng dụng nào yêu cầu khởi động lại cụ thể. (Restart theo yêu cầu người dùng)" -ForegroundColor Cyan
    }
    
    Write-Host "`n⚠ HÃY LƯU CÔNG VIỆC CỦA BẠN TRƯỚC KHI HỆ THỐNG RESTART!" -ForegroundColor Red
    
    $countdown = 10
    while ($countdown -gt 0) {
        # Sử dụng Write-Host -NoNewline và `r để cập nhật đếm ngược trên cùng một dòng
        Write-Host "`rHệ thống sẽ tự động khởi động lại trong $countdown giây... (Nhấn Ctrl+C để hủy) " -NoNewline -ForegroundColor Red
        Start-Sleep -Seconds 1
        $countdown--
    }
    
    Write-Host "`rĐang tiến hành khởi động lại..." -ForegroundColor Cyan
    Restart-Computer -Force
}

# ============================================================
# CHUONG TRINH CHINH
# ============================================================

# Thong ke
$successCount = 0
$failedCount = 0
$failedApps = @()
$rebootRequired = $false
$rebootApps = @()

# Header
Write-Host @"

============================================================
     SCRIPT CAI DAT PHAN MEM TU DONG - UI MODE
     Tong so phan mem: $($appList.Count)
============================================================
"@ -ForegroundColor Cyan

Write-Section "BAT DAU CAI DAT"

# Cai dat tung app
$index = 1
foreach ($app in $appList) {
    Write-Host "`n[$index/$($appList.Count)]" -ForegroundColor Magenta -NoNewline
    
    $result = Install-Application -name $app.name -url $app.url
    
    if ($result) {
        $successCount++
        
        if ($app.requireReboot) {
            $rebootRequired = $true
            $rebootApps += $app.name
            Write-Status "App nay yeu cau khoi dong lai Windows!" "warning"
        }
    } else {
        $failedCount++
        $failedApps += $app.name
    }
    
    $index++
    Start-Sleep -Seconds 2
}

# Don dep
Invoke-FinalCleanup

# ============================================================
# BÁO CÁO VÀ KẾT THÚC (LUÔN LUÔN RESTART)
# ============================================================

# Báo cáo
Write-Section "BAO CAO KET QUA"

Write-Status "Cai moi thanh cong: $successCount/$($appList.Count)" "success"
Write-Status "That bai: $failedCount/$($appList.Count)" "error"

if ($failedCount -gt 0) {
    Write-Host "`nDanh sach phan mem cai that bai:" -ForegroundColor Yellow
    foreach ($failedApp in $failedApps) {
        Write-Host "  [X] $failedApp" -ForegroundColor Red
    }
}

# --- BƯỚC 1: HIỂN THỊ THÔNG BÁO VÀ CHỜ NGƯỜI DÙNG NHẤN PHÍM ---
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "HOAN TAT! Nhan phim bat ky de CHUYEN SANG CHẾ ĐỘ RESTART TỰ ĐỘNG..." -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

pause 
# -------------------------------------------------------------------


# --- BƯỚC 2: TỰ ĐỘNG RESTART (VÔ ĐIỀU KIỆN) ---

# Gọi hàm đếm ngược và restart. Truyền $rebootApps (có thể rỗng) để hiển thị thông tin.
Invoke-AutoRestart -rebootApps $rebootApps

# Script sẽ kết thúc khi Restart-Computer được gọi.