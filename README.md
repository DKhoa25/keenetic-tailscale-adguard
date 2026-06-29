markdown

# 🚀 Keenetic Tailscale + AdGuard Home Installer

[![Version](https://img.shields.io/badge/version-5.0-blue.svg)](https://github.com/DKhoa25/keenetic-tailscale-adguard)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![OpenWrt](https://img.shields.io/badge/OpenWrt-22.03+-orange.svg)](https://openwrt.org/)
[![Keenetic](https://img.shields.io/badge/Keenetic-Compatible-brightgreen.svg)](https://keenetic.com/)

**Một script cài đặt tự động hoàn chỉnh cho Tailscale và AdGuard Home trên router Keenetic/OpenWrt.**

---

## 📋 Mục Lục

- [Tính Năng Nổi Bật](#-tính-năng-nổi-bật)
- [Yêu Cầu Hệ Thống](#-yêu-cầu-hệ-thống)
- [Cài Đặt Nhanh](#-cài-đặt-nhanh)
- [Hướng Dẫn Chi Tiết](#-hướng-dẫn-chi-tiết)
- [Cấu Hình Sau Cài Đặt](#-cấu-hình-sau-cài-đặt)
- [Xử Lý Sự Cố](#-xử-lý-sự-cố)
- [Gỡ Cài Đặt](#-gỡ-cài-đặt)
- [Đóng Góp](#-đóng-góp)
- [Giấy Phép](#-giấy-phép)

---

## ✨ Tính Năng Nổi Bật

### 🛡️ Tailscale
- **Mesh VPN** - Kết nối an toàn giữa các thiết bị
- **NAT Traversal** - Vượt tường lửa và NAT tự động
- **Zero Config** - Không cần cấu hình phức tạp
- **Magic DNS** - Truy cập thiết bị bằng tên thay vì IP
- **Tự động khởi động** - Service chạy cùng hệ thống

### 🛡️ AdGuard Home
- **Chặn quảng cáo** - Toàn bộ mạng nội bộ
- **Bảo vệ quyền riêng tư** - Không theo dõi người dùng
- **DNS over HTTPS/TLS** - Mã hóa truy vấn DNS
- **Giao diện quản lý** - Dashboard trực quan, dễ sử dụng
- **Bộ lọc tùy chỉnh** - Thêm filter theo nhu cầu

### ⚙️ Script Thông Minh
- ✅ **Tự động kiểm tra** - Môi trường, dung lượng, kết nối
- ✅ **Backup tự động** - Sao lưu cấu hình cũ trước khi cài mới
- ✅ **Xử lý lỗi thông minh** - Bắt lỗi và khôi phục khi cần
- ✅ **Log chi tiết** - Ghi nhật ký để dễ dàng debug
- ✅ **Hỗ trợ đa kiến trúc** - ARM, MIPS, x86, và nhiều hơn nữa

---

## 🔧 Yêu Cầu Hệ Thống

### Router/Hệ Thống
| Yêu cầu | Chi tiết |
|---------|----------|
| **Hệ điều hành** | OpenWrt 22.03+ hoặc Keenetic OS |
| **Kiến trúc** | aarch64, arm64, armv7l, mips, mips64, i386, x86_64 |
| **Dung lượng trống** | Tối thiểu 50MB trên partition `/opt` |
| **Kết nối mạng** | Cần truy cập Internet để tải gói và source |
| **Quyền** | Root/admin access |

### Phần Mềm Cần Thiết (Tự động cài)
- `opkg` - Trình quản lý gói OpenWrt
- `git` - Tải mã nguồn từ GitHub
- `wget` / `curl` - Tải file trực tiếp
- `ca-certificates` - Chứng chỉ SSL

---

## 📦 Cài Đặt Nhanh
# 1. Cập nhật Entware
opkg update

# 2. Cài các gói hỗ trợ SSL
opkg install wget-ssl ca-certificates

# 3. Clone
git clone https://github.com/DKhoa25/keenetic-tailscale-adguard.git /opt/keenetic-tailscale-adguard
cd /opt/keenetic-tailscale-adguard
# Cấp quyền và chạy
chmod +x install.sh
./install.sh

📖 Hướng Dẫn Chi Tiết
Quá Trình Cài Đặt

Script sẽ tự động thực hiện các bước sau:
Các Bước Chi Tiết
1️⃣ Kiểm Tra Môi Trường

    Kiểm tra quyền root

    Xác định kiến trúc CPU

    Đảm bảo đủ dung lượng trống

    Kiểm tra opkg và kết nối internet

2️⃣ Backup Cài Đặt Cũ

    Tự động backup thư mục /opt/keenetic-tailscale-adguard

    Lưu backup với timestamp

    Xóa thư mục cũ để cài đặt sạch

3️⃣ Cài Đặt Dependencies

    Tự động cài đặt các gói cần thiết:

        git - Quản lý source code

        wget / curl - Tải file

        ca-certificates - Chứng chỉ SSL

        Các gói cần thiết cho Tailscale và AdGuard

4️⃣ Tải Mã Nguồn

    Ưu tiên clone từ GitHub

    Fallback: Tải trực tiếp nếu clone thất bại

    Xác thực checksum file

5️⃣ Cài Đặt Chính

    Cài đặt Tailscale (VPN mesh)

    Cài đặt AdGuard Home (DNS filter)

    Cấu hình services

    Thiết lập auto-start

6️⃣ Kiểm Tra Sau Cài Đặt

    Xác nhận services đang chạy

    Hiển thị thông tin cài đặt

    Log chi tiết quá trình

⚙️ Cấu Hình Sau Cài Đặt
🔗 Cấu Hình Tailscale
bash

# Khởi động Tailscale
/etc/init.d/tailscale start

# Đăng nhập và kết nối
tailscale up

# Kiểm tra trạng thái
tailscale status

# Danh sách thiết bị kết nối
tailscale status --peers

# Tắt/Chạy Tailscale
tailscale down
tailscale up

🛡️ Cấu Hình AdGuard Home
bash

# Truy cập Web Interface
http://[ROUTER_IP]:3000

# Hoặc
http://192.168.1.1:3000

# Mật khẩu mặc định (nếu có)
Username: admin
Password: admin  # Thay đổi ngay sau khi đăng nhập

Cấu Hình DNS
bash

# Set DNS mặc định cho router
uci set network.lan.dns="127.0.0.1"
uci commit network
/etc/init.d/network restart

# Hoặc cấu hình DHCP
uci set dhcp.@dnsmasq[0].noresolv="1"
uci set dhcp.@dnsmasq[0].resolvfile="/tmp/resolv.conf.auto"
uci set dhcp.@dnsmasq[0].server="127.0.0.1#5335"
uci commit dhcp
/etc/init.d/dnsmasq restart

🌐 Cấu Hình Bộ Lọc

Bộ lọc khuyến nghị:
text

https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt
https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/SpywareFilter/sections/tracking_servers.txt
https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/BaseFilter/sections/adservers.txt

🔍 Xử Lý Sự Cố
Lỗi Thường Gặp
1. Cannot connect to internet
text

❌ Kiểm tra:
- Router có kết nối WAN không?
- DNS có hoạt động không? (ping 8.8.8.8)
- Cấu hình mạng có đúng không?

2. No space left on device
text

❌ Giải pháp:
- Xóa các gói không cần thiết: opkg remove [package]
- Xóa log cũ: rm -rf /var/log/*.log
- Mở rộng partition /opt

3. Tailscale not starting
text

❌ Kiểm tra:
- tailscale status
- /etc/init.d/tailscale status
- tailscale up --help
- Xem log: tail -f /var/log/tailscale.log

4. AdGuard Home không khởi động
bash

# Kiểm tra log
/etc/init.d/adguardhome status
tail -f /var/log/adguardhome.log

# Kiểm tra port
netstat -tuln | grep 3000
netstat -tuln | grep 5335

# Reset AdGuard
rm -rf /opt/adguardhome/data/*.db
/etc/init.d/adguardhome restart

5. Lỗi sau khi update OpenWrt
bash

# Reinstall các gói
opkg update
opkg install --force-reinstall tailscale adguardhome

# Restart services
/etc/init.d/tailscale restart
/etc/init.d/adguardhome restart

🔍 Kiểm Tra Log
bash

# Log cài đặt
cat /var/log/keenetic-install/install_*.log

# Tailscale
logread | grep tailscale
tail -f /var/log/tailscale.log

# AdGuard Home
logread | grep adguardhome
cat /opt/adguardhome/data/querylog.json | tail -20

🗑️ Gỡ Cài Đặt
bash

# 1. Dừng services
/etc/init.d/tailscale stop
/etc/init.d/adguardhome stop

# 2. Xóa services khỏi init.d
rm /etc/init.d/tailscale
rm /etc/init.d/adguardhome

# 3. Xóa thư mục cài đặt
rm -rf /opt/keenetic-tailscale-adguard
rm -rf /opt/tailscale
rm -rf /opt/adguardhome

# 4. Xóa cấu hình (optional)
rm -rf /etc/config/tailscale
rm -rf /etc/config/adguardhome

# 5. Xóa gói (optional)
opkg remove tailscale adguardhome --autoremove

# 6. Xóa log
rm -rf /var/log/keenetic-install

🤝 Đóng Góp

Chúng tôi rất hoan nghênh các đóng góp để cải thiện dự án!
Cách Đóng Góp

    Fork repository

    Tạo branch mới: git checkout -b feature/amazing-feature

    Commit thay đổi: git commit -m 'Add some amazing feature'

    Push lên branch: git push origin feature/amazing-feature

    Tạo Pull Request

Báo Cáo Lỗi

Vui lòng tạo issue với các thông tin:

    Mô tả lỗi chi tiết

    Log file (/var/log/keenetic-install/install_*.log)

    Thông tin router: uname -a, opkg list-installed

    Các bước tái hiện lỗi

📝 Changelog
Version 1.0 (Current)

    ✅ Thêm kiểm tra dung lượng đĩa

    ✅ Cải thiện xử lý lỗi

    ✅ Hỗ trợ nhiều kiến trúc hơn

    ✅ Backup tự động trước khi cài đặt

    ✅ Thêm fallback tải source

    ✅ Cải thiện logging và debug

    ✅ Tự động dọn dẹp file tạm

    ➕ Thêm hỗ trợ AdGuard Home

    ✅ Tối ưu hóa script

    🔧 Sửa lỗi cài đặt trên Keenetic

    ➕ Tích hợp Tailscale

    🔧 Cải thiện tương thích OpenWrt

📄 Giấy Phép

Dự án được phân phối dưới giấy phép MIT. Xem file LICENSE để biết thêm chi tiết.
text

MIT License

Copyright (c) 2024 DKhoa25

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
...

🙏 Cảm Ơn

    Tailscale - VPN mesh đơn giản và an toàn

    AdGuard - Bảo vệ quyền riêng tư và chặn quảng cáo

    OpenWrt - Nền tảng router mã nguồn mở

    Keenetic - Router chất lượng cao

📞 Liên Hệ

    GitHub: DKhoa25

    Issues: Báo cáo lỗi

    Discussions: Thảo luận

<div align="center"> <sub>Built with ❤️ by <a href="https://github.com/DKhoa25">DKhoa25</a></sub> </div> ```
