# === Tính từ thư mục gốc ===
$rootDir = Split-Path -Parent $PSScriptRoot
Set-Location $rootDir

# === Cấu hình ===
$projectPath = "src/EasyUpdater/EasyUpdater.Core/EasyUpdater.Core.csproj"
$projectFullPath = Join-Path $rootDir $projectPath
$outputDir = "BuildOutput"
$publishDir = "publish"

# === Load .csproj và metadata ===
[xml]$csproj = Get-Content $projectPath
$props = $csproj.Project.PropertyGroup | Where-Object { $_.Version }

$versionRaw = $props.Version
$ver = [System.Version]::Parse($versionRaw)
$newVer = "{0}.{1}.{2}" -f $ver.Major, $ver.Minor, ($ver.Build + 1)
$props.Version = $newVer
$csproj.Save($projectFullPath)

Write-Host "🔁 Đã tăng version lên: $newVer"

# === Lấy các metadata khác từ csproj ===
$appName    = $props.AppName
$gitUser    = $props.GitHubUser
$gitRepo    = $props.GitHubRepo
$zipName    = "$appName-v$newVer.zip"
$zipUrl     = "https://github.com/$gitUser/$gitRepo/releases/download/v$newVer/$zipName"

# 🧹 Reset thư mục
Remove-Item -Recurse -Force $outputDir, $publishDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
New-Item -ItemType Directory -Path $publishDir -Force | Out-Null

# 🔨 Build
dotnet publish $projectPath -c Release -o $publishDir

# 🗜️ Đóng gói
Compress-Archive -Path "$publishDir\*" -DestinationPath "$outputDir\$zipName" -Force

# 📝 Tạo JSON
$buildTime = Get-Date -Format "yyyy-MM-dd HH:mm"
$sha = (git rev-parse --short HEAD) -replace "`n",""
if (-not $sha) { $sha = "dev" }

$json = @{
    AppName   = $appName
    Version   = $newVer
    File      = $zipName
    Url       = $zipUrl
    Sha       = $sha
    Build     = $buildTime
    ChangeLog = "- Tự động cập nhật build lúc $buildTime"
}
$json | ConvertTo-Json -Depth 3 | Out-File "$outputDir\EasyUpdater.json" -Encoding utf8

Write-Host "`n✅ Đã tạo:"
Write-Host "   🗜️  $outputDir\$zipName"
Write-Host "   📄 $outputDir\EasyUpdater.json"

# 🧼 Xoá thư mục tạm
Remove-Item -Recurse -Force $publishDir -ErrorAction SilentlyContinue
Write-Host "🧹 Đã xoá thư mục tạm $publishDir"
