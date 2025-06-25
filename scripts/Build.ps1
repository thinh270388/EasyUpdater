param(
    [switch]$AutoVersion,
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

# 🧭 Ghi nhớ thư mục hiện tại
$prevDir = Get-Location

try {
    # === Xác định thư mục gốc ===
    $rootDir = Split-Path -Parent $PSScriptRoot
    Set-Location $rootDir

    # === Cấu hình đường dẫn ===
    $projectPath     = "src/EasyUpdater/EasyUpdater.Core/EasyUpdater.Core.csproj"
    $projectFullPath = Join-Path $rootDir $projectPath
    $outputDir       = "$rootDir\BuildOutput"
    $framework       = "net8.0-windows"

    # === Load metadata từ .csproj ===
    [xml]$csproj = Get-Content $projectFullPath
    $props = $csproj.Project.PropertyGroup | Where-Object { $_.Version }

    $appVersion = $props.Version
    if ($AutoVersion) {
        $ver = [System.Version]::Parse($appVersion)
        $newVer = "{0}.{1}.{2}" -f $ver.Major, $ver.Minor, ($ver.Build + 1)
        $props.Version = $newVer
        $csproj.Save($projectFullPath)
        Write-Host "🔁 Tăng version: $appVersion → $newVer"
        $appVersion = $newVer
    } else {
        Write-Host "🔒 Dùng version hiện tại: $appVersion"
    }

    # === Metadata từ .csproj
    $appName     = $props.AppName
    $gitUser     = $props.GitHubUser
    $gitRepo     = $props.GitHubRepo
    $zipName     = "$appName-v$appVersion.zip"
    $zipUrl      = "https://github.com/$gitUser/$gitRepo/releases/download/v$appVersion/$zipName"
    $versionUrl  = "https://raw.githubusercontent.com/$gitUser/$gitRepo/main/BuildOutput/EasyUpdater.json"

    # === Build ứng dụng
    Write-Host "🛠️  Bắt đầu publish: cấu hình $Configuration..."
    dotnet publish $projectPath -c $Configuration

    $publishDir = "$rootDir\src\EasyUpdater\EasyUpdater.Core\bin\$Configuration\$framework\publish"
    $buildDir   = Split-Path -Parent $publishDir

    # === Reset thư mục output
    Remove-Item -Recurse -Force $outputDir -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $outputDir | Out-Null

    # === Đóng gói zip
    Compress-Archive -Path "$publishDir\*" -DestinationPath "$outputDir\$zipName" -Force

    # === Sinh EasyUpdater.json
    $buildTime = Get-Date -Format "yyyy-MM-dd HH:mm"
    $sha = (git rev-parse --short HEAD) -replace "`n",""
    if (-not $sha) { $sha = "dev" }

    $json = @{
        AppName     = $appName
        Version     = $appVersion
        File        = $zipName
        ZipUrl      = $zipUrl
        VersionUrl  = $versionUrl
        GitHubUser  = $gitUser
        GitHubRepo  = $gitRepo
        Build       = $buildTime
        Sha         = $sha
        ChangeLog   = "- Build tự động lúc $buildTime"
    }

    $jsonText = $json | ConvertTo-Json -Depth 3

    # === Ghi ra 3 nơi
    $jsonText | Out-File "$outputDir\EasyUpdater.json" -Encoding utf8
    $jsonText | Out-File "$publishDir\EasyUpdater.json" -Encoding utf8
    $jsonText | Out-File "$buildDir\EasyUpdater.json" -Encoding utf8

    # === Log kết quả
    Write-Host "`n✅ Build thành công:"
    Write-Host "   🗜️  $outputDir\$zipName"
    Write-Host "   📄 EasyUpdater.json tại:"
    Write-Host "      • $outputDir"
    Write-Host "      • $publishDir"
    Write-Host "      • $buildDir"
    Write-Host "📁 Publish nằm tại: $publishDir"

} finally {
    # 🔁 Trả lại thư mục gốc
    Set-Location $prevDir
}
