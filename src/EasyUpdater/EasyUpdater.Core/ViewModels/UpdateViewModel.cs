using CommunityToolkit.Mvvm.ComponentModel;
using EasyUpdater.Core.Models;
using EasyUpdater.Core.Services;
using System;
using System.IO;
using System.Threading.Tasks;

namespace EasyUpdater.Core.ViewModels
{
    public partial class UpdateViewModel : ObservableObject
    {
        private readonly UpdateContext _context;
        private readonly UpdateService _service = new();

        [ObservableProperty] private double progress;
        [ObservableProperty] private string status = "🔍 Đang kiểm tra cập nhật...";
        [ObservableProperty] private string title = "Cập nhật phàn mềm...";

        public UpdateViewModel(UpdateContext context)
        {
            _context = context;

            Title = $"🔄 Cập nhật phần mềm {Path.GetFileName(context.Url)}";
            RunAsync();
        }

        private async void RunAsync()
        {
            bool ok = await _service.RunAsync(
                _context,
                new Progress<string>(msg => Status = msg),
                p => Progress = p
            );

            if (ok)
            {
                Status = "✅ Đã sẵn sàng cập nhật.";
                await Task.Delay(1000);
                System.Windows.Application.Current.Shutdown();
            }
            else
            {
                Status = "❌ Cập nhật thất bại.";
            }
        }
    }
}
