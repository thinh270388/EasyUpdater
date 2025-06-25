# 🚀 EasyUpdater

**EasyUpdater** là thư viện .NET giúp cập nhật ứng dụng WPF/WinForms một cách đơn giản thông qua file `.zip`, không cần quyền admin — có giao diện UI tối giản, và dễ tích hợp vào bất kỳ app nào.

## ✨ Tính năng

- 🔍 Kiểm tra phiên bản mới thông qua file JSON online
- ⬇️ Tự động tải `.zip` bản cập nhật
- 🗜️ Giải nén sau khi ứng dụng chính thoát
- 🪟 Có giao diện cập nhật (WPF) với progress rõ ràng
- 🔄 Tự khởi động lại ứng dụng sau khi cập nhật thành công
- 🧼 Không để lại file tạm, log lỗi nếu cập nhật lỗi
- ✅ Không yêu cầu quyền admin khi cập nhật

---

## 🚀 Cài đặt

dotnet add package EasyUpdater.Core

🔧 Cách hoạt động
1. Tạo một file JSON đặt online, ví dụ EasyUpdater.json:
{
  "AppName": "EasyMix",
  "Version": "1.0.2",
  "File": "EasyMix-v1.0.2.zip",
  "Url": "https://github.com/youruser/EasyMix/releases/download/v1.0.2/EasyMix-v1.0.2.zip",
  "Sha": "abc123",
  "Build": "2025-06-24 07:57",
  "ChangeLog": "- Cải tiến hiệu năng\n- Cập nhật UI"
}

2. Trong app chính:
var context = new UpdateContext
{
    Url = json.url,
    FileName = json.file,
    AppExe = Environment.ProcessPath!
};

var vm = new UpdateViewModel(context);
var win = new UpdateView { DataContext = vm };
win.ShowDialog();
