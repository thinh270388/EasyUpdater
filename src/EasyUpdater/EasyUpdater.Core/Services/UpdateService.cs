using EasyUpdater.Core.Models;
using System;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;

namespace EasyUpdater.Core.Services
{
    public class UpdateService
    {
        public async Task<bool> RunAsync(UpdateContext ctx, IProgress<string> log = null, Action<double> progress = null)
        {
            try
            {
                // Bước 1: Tải về file zip
                string zipPath = Path.Combine(Path.GetTempPath(), ctx.FileName);
                log?.Report("⬇️ Đang tải gói cập nhật...");
                progress?.Invoke(10);
                await Task.Delay(500);

                using var http = new HttpClient();
                var zipBytes = await http.GetByteArrayAsync(ctx.Url);
                await File.WriteAllBytesAsync(zipPath, zipBytes);

                log?.Report("🔄 Chuẩn bị cập nhật...");
                progress?.Invoke(30);
                await Task.Delay(500);

                // Bước 2: Tạo lệnh PowerShell
                string psCommand = $"""
            Start-Sleep -Seconds 2;
            Expand-Archive -Path '{zipPath}' -DestinationPath '{AppContext.BaseDirectory}' -Force;
            Remove-Item '{zipPath}';
            Start-Process -FilePath '{ctx.AppExe}';
            """;

                log?.Report("🚀 Gói cập nhật đã sẵn sàng, đang chờ app khởi động lại...");
                progress?.Invoke(50);
                await Task.Delay(500);

                // Bước 3: Chạy PowerShell ẩn
                Process.Start(new ProcessStartInfo
                {
                    FileName = "powershell",
                    Arguments = $"-NoProfile -WindowStyle Hidden -Command \"{psCommand}\"",
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    WindowStyle = ProcessWindowStyle.Hidden
                });

                progress?.Invoke(100);
                await Task.Delay(500);
                return true;
            }
            catch (Exception ex)
            {
                log?.Report($"❌ Lỗi cập nhật: {ex.Message}");

                try
                {
                    string errorDir = Path.Combine(AppContext.BaseDirectory, "Errors");
                    Directory.CreateDirectory(errorDir);
                    string errorFile = Path.Combine(errorDir, $"update_error_{DateTime.Now:yyyyMMdd_HHmmss}.log");
                    File.WriteAllText(errorFile, ex.ToString());
                }
                catch { /* ignore */ }

                return false;
            }
        }
    }
}
