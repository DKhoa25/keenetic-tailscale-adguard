🚀 Keenetic Tailscale + AdGuard Installer

https://img.shields.io/badge/version-5.0-blue.svg
https://img.shields.io/badge/license-MIT-green.svg
https://img.shields.io/badge/OpenWrt-22.03+-orange.svg
https://img.shields.io/badge/Keenetic-Compatible-red.svg
<div align="center"> <h3>Giải pháp tự động cài đặt Tailscale VPN & AdGuard Home trên router Keenetic</h3> <p><strong>Version 5.0 - Hoàn thiện với nhiều cải tiến vượt trội</strong></p> </div>
📖 Tổng quan

Script cài đặt tự động Tailscale (VPN mesh) và AdGuard Home (chặn quảng cáo/DNS) trên các router Keenetic chạy hệ điều hành OpenWrt/KeeneticOS.

Điểm nổi bật:

    🔄 Cài đặt hoàn toàn tự động

    🛡️ Bảo mật với xác minh checksum

    📝 Logging đầy đủ để dễ dàng debug

    🔙 Tự động backup và restore khi có lỗi

    🎨 Giao diện đẹp mắt với màu sắc và icon

    ⚡ Tối ưu hóa cho router với dung lượng hạn chế

✨ Tính năng
Cốt lõi

    ✅ Tailscale VPN: Kết nối mesh network an toàn giữa các thiết bị

    ✅ AdGuard Home: Chặn quảng cáo, bảo vệ DNS, tăng tốc duyệt web

    ✅ Tự động hóa: Chỉ cần chạy 1 lệnh duy nhất

    ✅ Xử lý lỗi thông minh: Nhiều lớp fallback và recovery

Nâng cao

    🔍 Kiểm tra môi trường: CPU architecture, dung lượng đĩa, kết nối internet

    📦 Quản lý dependencies: Tự động cài Git, wget, curl, ca-certificates

    💾 Backup thông minh: Tự động backup cài đặt cũ trước khi nâng cấp

    🔐 Bảo mật: Xác minh checksum, kiểm tra chữ ký

    📊 Logging chi tiết: Lưu log để dễ dàng kiểm tra và debug

    🎯 Hỗ trợ đa nền tảng: aarch64, armv7l, mips, x86_64

📋 Yêu cầu hệ thống
Yêu cầu	Chi tiết
Router	Keenetic hoặc OpenWrt 22.03+
Kiến trúc	aarch64, armv7l, mips, mips64, i386, x86_64
Dung lượng	Tối thiểu 50MB trống
Kết nối	Internet để tải dependencies và source
Quyền	Root access (admin)
RAM	Khuyến nghị 128MB+
🚀 Cài đặt nhanh
Cách 1: Cài đặt tự động (Khuyến nghị)
bash

# Tải và chạy script installer
curl -L https://raw.githubusercontent.com/DKhoa25/keenetic-tailscale-adguard/main/installer.sh -o /tmp/installer.sh
chmod +x /tmp/installer.sh
/tmp/installer.sh

Cách 2: Sử dụng wget
bash

wget -O /tmp/installer.sh https://raw.githubusercontent.com/DKhoa25/keenetic-tailscale-adguard/main/installer.sh
chmod +x /tmp/installer.sh
/tmp/installer.sh

Cách 3: Tải trực tiếp về router
bash

# SSH vào router và thực hiện
cd /tmp
wget https://raw.githubusercontent.com/DKhoa25/keenetic-tailscale-adguard/main/installer.sh
sh installer.sh

📖 Hướng dẫn chi tiết
🔄 Quá trình cài đặt

Script sẽ thực hiện các bước sau:
📝 Cấu trúc thư mục
text

/opt/keenetic-tailscale-adguard/    # Thư mục cài đặt chính
├── install.sh                      # Script cài đặt chính
├── config/                         # File cấu hình
│   ├── tailscale.conf
│   └── adguard.conf
├── scripts/                        # Script hỗ trợ
│   ├── start.sh
│   └── stop.sh
└── logs/                           # Log files (nếu có)

/var/log/keenetic-install/          # Log của installer
└── install_YYYYMMDD_HHMMSS.log

/etc/config/                        # Cấu hình hệ thống
├── tailscale
└── adguardhome

🎯 Sau khi cài đặt
1. Kiểm tra Tailscale
bash

# Kiểm tra trạng thái
tailscale status

# Đăng nhập (lấy link từ output)
tailscale up

# Kiểm tra interface
ip addr show tailscale0

2. Cấu hình AdGuard Home
bash

# Kiểm tra trạng thái
/etc/init.d/adguardhome status

# Truy cập web interface
# Mở trình duyệt: http://[IP-router]:3000
# Mặc định: http://192.168.1.1:3000

3. Các lệnh hữu ích
bash

# Xem log cài đặt
cat /var/log/keenetic-install/install_*.log

# Khởi động lại dịch vụ
/etc/init.d/tailscale restart
/etc/init.d/adguardhome restart

# Xem trạng thái chi tiết
ps | grep -E 'tailscale|adguard'
netstat -tulpn | grep -E '53|3000|41641'

🔧 Xử lý sự cố
❌ Lỗi thường gặp
<details> <summary><b>Không có kết nối internet</b></summary>
bash

# Kiểm tra DNS
ping -c 2 8.8.8.8

# Kiểm tra kết nối
ping -c 2 google.com

# Sửa DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf

</details><details> <summary><b>Không đủ dung lượng</b></summary>
bash

# Kiểm tra dung lượng
df -h

# Dọn dẹp package cache
opkg clean

# Xóa log cũ
find /var/log -name "*.log" -mtime +30 -delete

# Xóa thư mục tạm
rm -rf /tmp/*.ipk

</details><details> <summary><b>Không thể cài Git</b></summary>
bash

# Cập nhật package list
opkg update

# Cài thủ công
opkg install git git-http ca-certificates

# Nếu vẫn lỗi, tải binary
wget -O /usr/bin/git https://github.com/git/git/raw/master/git
chmod +x /usr/bin/git

</details><details> <summary><b>Port đã được sử dụng</b></summary>
bash

# Kiểm tra port 53 (DNS)
netstat -tulpn | grep :53

# Kiểm tra port 3000 (AdGuard)
netstat -tulpn | grep :3000

# Dừng dịch vụ xung đột
/etc/init.d/dnsmasq stop

</details>
📊 Debug
bash

# Xem log realtime
tail -f /var/log/keenetic-install/install_*.log

# Kiểm tra system logs
logread -e "tailscale|adguard"

# Kiểm tra resource
top -n 1 | head -10
free -m

🔒 Bảo mật
Tài khoản mặc định

    AdGuard Home: Không có mật khẩu mặc định, sẽ yêu cầu tạo khi lần đầu truy cập

    Tailscale: Đăng nhập qua link xác thực, không lưu mật khẩu

Khuyến nghị bảo mật

    ✅ Thay đổi mật khẩu admin router

    ✅ Đặt mật khẩu mạnh cho AdGuard Home

    ✅ Bật firewall cho Tailscale

    ✅ Thường xuyên cập nhật phiên bản mới

    ✅ Sử dụng HTTPS cho AdGuard Home

🔄 Cập nhật và nâng cấp
Cập nhật lên phiên bản mới
bash

# Chạy lại installer (tự động backup và upgrade)
/tmp/installer.sh

# Hoặc tải và chạy lại
curl -L https://raw.githubusercontent.com/DKhoa25/keenetic-tailscale-adguard/main/installer.sh | sh

Kiểm tra phiên bản
bash

# Kiểm tra phiên bản script
grep "Version:" /opt/keenetic-tailscale-adguard/install.sh

# Kiểm tra phiên bản Tailscale
tailscale version

# Kiểm tra phiên bản AdGuard
/usr/bin/adguardhome --version

💡 Mẹo và thủ thuật
Tối ưu hiệu suất
bash

# Điều chỉnh buffer cho Tailscale
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" >> /etc/sysctl.conf

# Cache DNS cho AdGuard
echo "cache_size = 1000000" >> /etc/adguardhome/AdGuardHome.yaml

Tự động khởi động
bash

# Thêm vào khởi động
/etc/init.d/tailscale enable
/etc/init.d/adguardhome enable

# Khởi động lại để test
reboot

Backup & Restore cấu hình
bash

# Backup
tar -czf /tmp/keenetic_backup.tar.gz \
    /etc/config/tailscale \
    /etc/config/adguardhome \
    /opt/keenetic-tailscale-adguard

# Restore
tar -xzf /tmp/keenetic_backup.tar.gz -C /

🤝 Đóng góp

Chúng tôi luôn chào đón sự đóng góp từ cộng đồng!
Cách đóng góp

    🍴 Fork repository

    🔧 Tạo branch mới (git checkout -b feature/AmazingFeature)

    📝 Commit thay đổi (git commit -m 'Add some AmazingFeature')

    📤 Push lên branch (git push origin feature/AmazingFeature)

    🎉 Tạo Pull Request

Báo lỗi

Vui lòng tạo Issue với:

    📋 Phiên bản script

    🖥️ Router model và firmware

    📝 Log đầy đủ

    🔄 Các bước tái hiện lỗi

📜 License

Distributed under the MIT License. See LICENSE for more information.
🙏 Cảm ơn

    Tailscale - VPN mesh tuyệt vời

    AdGuard Team - Giải pháp chặn quảng cáo hiệu quả

    OpenWrt - Hệ điều hành mạnh mẽ cho router

    Cộng đồng Keenetic Việt Nam

📞 Hỗ trợ

    GitHub Issues: Create Issue

    Telegram: @keenetic_tailscale

    Email: support@dkhoa.dev

<div align="center"> <p>⭐ Star us on GitHub — it motivates us a lot! ⭐</p> <p><sub>Made with ❤️ by DKhoa25 and contributors</sub></p> </div>
