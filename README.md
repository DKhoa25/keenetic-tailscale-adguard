markdown

# 🚀 Tailscale + AdGuard Home + NTP Installer for Keenetic

[![Version](https://img.shields.io/badge/version-3.0-blue.svg)](https://github.com/yourusername/keenetic-tailscale-adguard)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Keenetic](https://img.shields.io/badge/Keenetic-OS_3.7+-orange.svg)](https://keenetic.com)
[![OpenWrt](https://img.shields.io/badge/OpenWrt-22.03+-yellow.svg)](https://openwrt.org)

> **Script tự động hóa hoàn chỉnh để cài đặt Tailscale VPN, AdGuard Home DNS Filter và NTP trên thiết bị Keenetic**

---

## 📋 Mục lục

- [Tính năng nổi bật](#-tính-năng-nổi-bật)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Cài đặt nhanh](#-cài-đặt-nhanh)
- [Cấu hình](#-cấu-hình)
- [Hướng dẫn sử dụng](#-hướng-dẫn-sử-dụng)
- [Quản lý dịch vụ](#-quản-lý-dịch-vụ)
- [Kiểm tra và Debug](#-kiểm-tra-và-debug)
- [Xử lý sự cố](#-xử-lý-sự-cố)
- [Gỡ cài đặt](#-gỡ-cài-đặt)
- [Cấu trúc hệ thống](#-cấu-trúc-hệ-thống)
- [Hỏi đáp](#-hỏi-đáp)
- [Changelog](#-changelog)
- [Giấy phép](#-giấy-phép)

---

## 🌟 Tính năng nổi bật

### 🛡️ **Tailscale VPN**
- ✅ **Mesh VPN** - Kết nối an toàn giữa các thiết bị
- ✅ **Exit Node** - Sử dụng router làm cổng ra Internet
- ✅ **Subnet Routing** - Advertise subnet LAN tự động
- ✅ **SSH Access** - Kết nối SSH qua Tailscale
- ✅ **Tự động login** - Hỗ trợ Auth Key tương tác

### 🛡️ **AdGuard Home DNS**
- ✅ **Chặn quảng cáo** - Block ads và trackers toàn mạng
- ✅ **DNS over HTTPS** - Hỗ trợ DNS bảo mật
- ✅ **Tự động cấu hình** - Setup DNS cho toàn bộ hệ thống
- ✅ **Web Interface** - Quản lý dễ dàng qua port 3000
- ✅ **DNS Cache** - Tăng tốc duyệt web

### 🕐 **NTP và Múi giờ Việt Nam**
- ✅ **Đồng bộ thời gian** - Tự động sync mỗi 6 giờ
- ✅ **NTP Servers Việt Nam** - `0.vn.pool.ntp.org`
- ✅ **Múi giờ VN** - Asia/Ho_Chi_Minh
- ✅ **Hardware Clock** - Cập nhật clock hardware

### 🔧 **Tự động hóa và Phục hồi**
- ✅ **Auto-restart** - Tự động restart service chết
- ✅ **DNS Conflict Fix** - Giải quyết xung đột port 53
- ✅ **Cron Jobs** - Lên lịch bảo trì tự động
- ✅ **Logging đầy đủ** - Theo dõi mọi hoạt động
- ✅ **Subnet Auto-detect** - Tự động phát hiện cấu hình mạng

---

## ⚙️ Yêu cầu hệ thống

| Thành phần | Yêu cầu |
|------------|---------|
| **Thiết bị** | Keenetic (KN-1010, KN-2010, KN-3010, Hopper, ...) |
| **Hệ điều hành** | Keenetic OS 3.7+ |
| **Kết nối Internet** | Cần thiết để tải packages |
| **Dung lượng** | Tối thiểu 50MB trống |
| **RAM** | Tối thiểu 128MB |
| **Quyền** | Root access (admin) |
| **OPKG** | Đã cài đặt và cấu hình |

### ✅ **Kiểm tra hệ thống**
```bash
# Kiểm tra phiên bản Keenetic OS
cat /etc/version

# Kiểm tra dung lượng
df -h /opt

# Kiểm tra RAM
free -m

# Kiểm tra opkg
opkg --version

🚀 Cài đặt nhanh

## 1. Clone Repository
cd opt
git clone  https://github.com/DKhoa25/keenetic-tailscale-adguard.git
cd arch-setup-script

## 2. Chạy Script
bash

chmod +x arch-setup.sh
sudo ./arch-setup.sh



1️⃣ Tải script
bash

# Tải trực tiếp từ GitHub
wget -O install.sh https://raw.githubusercontent.com/DKhoa25/keenetic-tailscale-adguard/main/install.sh

# Hoặc tạo file trực tiếp
nano install.sh
# Paste nội dung script vào

2️⃣ Phân quyền và chạy
bash

chmod +x install.sh
./install.sh

3️⃣ Theo dõi quá trình cài đặt

Script sẽ tự động:

    ✅ Kiểm tra quyền root

    ✅ Phát hiện subnet mạng

    ✅ Cài đặt packages

    ✅ Tạo cấu trúc thư mục

    ✅ Cấu hình NTP và múi giờ VN

    ✅ Thiết lập AdGuard Home

    ✅ Cấu hình Tailscale với Auth Key

    ✅ Thiết lập Firewall rules

    ✅ Cấu hình CRON jobs

4️⃣ Nhập Tailscale Auth Key

Khi script yêu cầu, nhập Auth Key từ Tailscale Admin Console:
text

==========================================
VUI LÒNG NHẬP TAILSCALE AUTH KEY
==========================================
Lấy auth key tại: https://login.tailscale.com/admin/settings/keys

Nhập auth key (hoặc để trống để nhập sau):
> tskey-auth-xxxxxxxxxxxxxxxxxxxxxxxx

5️⃣ Khởi động dịch vụ

Sau khi cài đặt hoàn tất:
bash

# Khởi động tất cả dịch vụ
/opt/bin/start-all.sh

# Kiểm tra trạng thái
/opt/bin/check-all.sh

⚙️ Cấu hình
📁 File cấu hình chính
File	Mô tả
/opt/etc/tailscale.conf	Cấu hình Tailscale (Auth Key, Routes, Exit Node)
/opt/etc/AdGuardHome/AdGuardHome.yaml	Cấu hình AdGuard Home
/opt/etc/ntp.conf	Cấu hình NTP servers
/opt/etc/crontab	CRON jobs lên lịch
/opt/etc/ndm/netfilter.d/100-tailscale.sh	Firewall rules
🔑 Tailscale Configuration

File: /opt/etc/tailscale.conf
bash

# Auth key từ Tailscale Admin Console
export TS_AUTHKEY="tskey-auth-xxxxxxxxxxxxxxxxxxxxxxxx"

# Subnet muốn advertise (tự động phát hiện)
export TS_ROUTES="192.168.1.0/24"

# Các tính năng
export TS_EXIT_NODE="true"    # Bật Exit Node
export TS_SSH="true"           # Bật SSH qua Tailscale

# Không sửa
export TS_ACCEPT_DNS="false"
export TS_NETFILTER_MODE="off"

🛡️ AdGuard Home Configuration

Sau khi cài đặt, truy cập web interface:
text

http://[IP_ROUTER]:3000

    Username: admin (thiết lập lần đầu)

    Password: thiết lập lần đầu

Cấu hình DNS upstream:
text

https://dns.google/dns-query
https://cloudflare-dns.com/dns-query
https://dns.quad9.net/dns-query

📖 Hướng dẫn sử dụng
🚀 Khởi động dịch vụ
bash

# Khởi động tất cả dịch vụ
/opt/bin/start-all.sh

# Khởi động từng dịch vụ
/opt/etc/init.d/S95ntp start        # NTP
/opt/etc/init.d/S97adguardhome start # AdGuard Home
/opt/etc/init.d/S98tailscaled start  # tailscaled
/opt/etc/init.d/S99tailscale start   # Tailscale

# Restart tất cả dịch vụ
/opt/bin/restart-services.sh

🛑 Dừng dịch vụ
bash

# Dừng tất cả dịch vụ
/opt/etc/init.d/S99tailscale stop
/opt/etc/init.d/S98tailscaled stop
/opt/etc/init.d/S97adguardhome stop
/opt/etc/init.d/S95ntp stop

🔍 Kiểm tra trạng thái
bash

# Kiểm tra tổng hợp
/opt/bin/check-all.sh

# Kiểm tra từng dịch vụ
/opt/etc/init.d/S97adguardhome status
/opt/etc/init.d/S99tailscale status
/opt/etc/init.d/S95ntp status

# Kiểm tra Tailscale
tailscale status
tailscale ping [IP_TAILSCALE]

# Kiểm tra DNS
nslookup google.com 127.0.0.1
dig @127.0.0.1 google.com

🔑 Cập nhật Auth Key
bash

# Sử dụng script tự động
/opt/bin/set-authkey.sh

# Hoặc chỉnh sửa thủ công
nano /opt/etc/tailscale.conf
# Sửa dòng export TS_AUTHKEY="..."
# Restart Tailscale
/opt/etc/init.d/S99tailscale restart

🕐 Đồng bộ thời gian thủ công
bash

# Đồng bộ ngay lập tức
/opt/bin/sync-time.sh

# Kiểm tra thời gian hiện tại
date
date '+%Y-%m-%d %H:%M:%S %Z'

🔧 Fix DNS Conflict
bash

# Nếu DNS không hoạt động
/opt/bin/fix-dns-conflict.sh

# Reset DNS configuration
/opt/bin/setup-dns.sh

📊 Quản lý dịch vụ
📋 Thứ tự khởi động và dependencies
text

┌─────────────────────────────────────────────┐
│             System Boot                     │
└─────────────────┬───────────────────────────┘
                  │
         ┌────────▼────────┐
         │   S95ntp        │  ← Đồng bộ thời gian
         │   (NTP)         │
         └────────┬────────┘
                  │
         ┌────────▼────────┐
         │ S97adguardhome  │  ← DNS Server (port 53)
         │  (AdGuard Home) │
         └────────┬────────┘
                  │
         ┌────────▼────────┐
         │ S98tailscaled   │  ← Tailscale Daemon
         │  (tailscaled)   │
         └────────┬────────┘
                  │
         ┌────────▼────────┐
         │ S99tailscale    │  ← Tailscale Client
         │   (Tailscale)   │  + Exit Node
         └─────────────────┘

🔄 Cron Jobs Schedule
Thời gian	Tác vụ	Mô tả
0 5 * * *	restart-services.sh	Restart toàn bộ dịch vụ
*/30 * * * *	check-and-restart.sh	Kiểm tra và restart service chết
0 * * * *	fix-dns-conflict.sh	Fix conflict port 53
0 */6 * * *	sync-time.sh	Đồng bộ thời gian
@reboot	setup-dns.sh	Setup DNS sau reboot
📁 Log Files
bash

# Xem log của từng dịch vụ
tail -f /opt/var/log/auto-restart.log      # Auto-restart
tail -f /opt/var/log/restart-services.log   # Manual restart
tail -f /opt/var/log/dns-setup.log          # DNS setup
tail -f /opt/var/log/ntp.log                # NTP
tail -f /opt/var/log/time-sync.log          # Time sync
tail -f /opt/var/log/cron.log               # Cron jobs
tail -f /tmp/adguardhome.log                # AdGuard Home runtime
tail -f /tmp/tailscaled.log                 # Tailscale daemon

# Log rotation (tự động giới hạn 1000 dòng)

🧪 Kiểm tra và Debug
🔍 Kiểm tra toàn diện
bash

# Script kiểm tra toàn bộ hệ thống
/opt/bin/check-all.sh

Output mẫu:
text

========================================
   TAILSCALE & ADGUARD HOME CHECK
========================================

1. ADGUARD HOME STATUS:
------------------------
✓ AdGuard Home dang chay
  PID: 12345
  Port: 0.0.0.0:53

2. TAILSCALE STATUS:
------------------------
✓ Tailscale dang chay
100.86.208.78   computer1   active   offline
100.86.208.79   computer2   active   online

Interface:
inet 100.86.208.78/32 scope global tailscale0

3. DNS CONFIG:
------------------------
--- /tmp/resolv.conf.d/head ---
nameserver 127.0.0.1
options ndots:0

✓ DNS test thanh cong

4. IP FORWARDING:
------------------------
✓ IP Forward: enabled

5. FIREWALL RULES:
------------------------
Chain FORWARD (policy ACCEPT)
target     prot opt source         destination
ts-forward  all  --  anywhere      anywhere

6. NTP STATUS:
------------------------
✓ NTP dang chay
  Thoi gian: 2026-06-29 15:30:45 +07

🧰 Kiểm tra từng thành phần
bash

# 1. Kiểm tra DNS
nslookup google.com 127.0.0.1
dig @127.0.0.1 google.com

# 2. Kiểm tra Tailscale
tailscale status
tailscale ping <hostname>
tailscale ip -4

# 3. Kiểm tra Firewall
iptables -L -n -v | grep -E "tailscale|ts-"
iptables -t nat -L -n -v | grep -E "tailscale|ts-"

# 4. Kiểm tra NTP
ntpq -p  # Nếu có ntpq
chronyc sources  # Nếu có chronyc

# 5. Kiểm tra port
netstat -tlnp | grep -E ":(53|3000|41641)"

# 6. Kiểm tra process
ps | grep -E "tailscale|AdGuardHome|ntpd|crond"

📊 Performance Monitoring
bash

# Xem CPU và Memory usage
top -b -n 1 | grep -E "tailscale|AdGuardHome"

# Xem network traffic
ifconfig tailscale0
ip -s link show tailscale0

# Xem disk usage
df -h /opt
du -sh /opt/var/log/

🐛 Xử lý sự cố
❌ DNS không hoạt động

Vấn đề: Không thể truy cập internet, DNS timeout

Giải pháp:
bash

# 1. Kiểm tra AdGuard Home
/opt/etc/init.d/S97adguardhome status

# 2. Fix DNS conflict
/opt/bin/fix-dns-conflict.sh

# 3. Kiểm tra port 53
netstat -tlnp | grep :53

# 4. Restart AdGuard Home
/opt/etc/init.d/S97adguardhome restart

# 5. Kiểm tra DNS test
nslookup google.com 127.0.0.1

❌ Tailscale không kết nối

Vấn đề: Tailscale status "Logged out" hoặc không có IP

Giải pháp:
bash

# 1. Kiểm tra Auth Key
cat /opt/etc/tailscale.conf | grep TS_AUTHKEY

# 2. Cập nhật Auth Key
/opt/bin/set-authkey.sh

# 3. Restart Tailscale
/opt/etc/init.d/S99tailscale restart

# 4. Kiểm tra log
tail -f /tmp/tailscaled.log

# 5. Manual login (nếu cần)
tailscale up --authkey=tskey-auth-XXX --accept-dns=false --netfilter-mode=off

❌ Port 53 bị chiếm dụng

Vấn đề: AdGuard Home không khởi động được vì port 53 đã được sử dụng

Giải pháp:
bash

# 1. Xem process đang dùng port 53
netstat -tlnp | grep :53

# 2. Kill process
kill -9 <PID>

# 3. Chạy fix script
/opt/bin/fix-dns-conflict.sh

# 4. Restart AdGuard Home
/opt/etc/init.d/S97adguardhome restart

❌ Thời gian không chính xác

Vấn đề: Thời gian hệ thống sai lệch

Giải pháp:
bash

# 1. Kiểm tra múi giờ
date
echo $TZ

# 2. Đồng bộ thủ công
/opt/bin/sync-time.sh

# 3. Kiểm tra NTP servers
cat /opt/etc/ntp.conf

# 4. Restart NTP
/opt/etc/init.d/S95ntp restart

# 5. Set timezone lại
export TZ='Asia/Ho_Chi_Minh'

❌ Không có kết nối internet sau cài đặt

Vấn đề: Mất kết nối internet, không thể ping

Giải pháp:
bash

# 1. Kiểm tra DNS
ping 8.8.8.8  # Kiểm tra IP connectivity
ping google.com  # Kiểm tra DNS

# 2. Temporarily disable AdGuard Home
/opt/etc/init.d/S97adguardhome stop

# 3. Check default DNS
cat /etc/resolv.conf

# 4. Restore default DNS
ndmc -c "dns server enable"
ndmc -c "dns forward off"

# 5. Kiểm tra lại
ping google.com

❌ CRON không chạy

Vấn đề: Các job scheduled không thực thi

Giải pháp:
bash

# 1. Kiểm tra CRON daemon
ps | grep crond

# 2. Restart CRON
pkill crond
crond -c /opt/etc/crontabs -L /opt/var/log/cron.log

# 3. Kiểm tra crontab
cat /opt/etc/crontab

# 4. Xem log CRON
tail -f /opt/var/log/cron.log

🔄 Restart toàn bộ hệ thống
bash

# Phương pháp 1: Script restart
/opt/bin/restart-services.sh

# Phương pháp 2: Restart từng bước
/opt/etc/init.d/S99tailscale stop
/opt/etc/init.d/S98tailscaled stop
/opt/etc/init.d/S97adguardhome stop
sleep 3
/opt/etc/init.d/S97adguardhome start
/opt/etc/init.d/S98tailscaled start
/opt/etc/init.d/S99tailscale start

# Phương pháp 3: Khởi động lại toàn bộ
/opt/bin/start-all.sh

🗑️ Gỡ cài đặt
Uninstall Script
bash

# Chạy script uninstall
/opt/bin/uninstall.sh

# Xác nhận gỡ cài đặt
⚠️ Ban co chac chan muon go cai dat?
Nhap 'yes' de tiep tuc: yes

Quá trình uninstall:

    ✅ Dừng tất cả dịch vụ

    ✅ Xóa init scripts

    ✅ Xóa netfilter rules

    ✅ Xóa configuration files

    ✅ Xóa utility scripts

    ✅ Restore DNS config mặc định

Xóa packages (Optional)
bash

# Sau khi chạy uninstall, có thể xóa packages
opkg remove tailscale adguardhome-go ntpclient

# Xóa thư mục /opt (cẩn thận!)
# rm -rf /opt

📁 Cấu trúc hệ thống
Cây thư mục chi tiết
text

/opt/
├── bin/
│   ├── AdGuardHome              # AdGuard binary
│   ├── tailscaled               # Tailscale daemon
│   ├── tailscale                # Tailscale client
│   ├── start-all.sh             # Khởi động tất cả dịch vụ
│   ├── check-all.sh             # Kiểm tra tổng hợp
│   ├── fix-dns-conflict.sh      # Fix DNS conflict
│   ├── setup-dns.sh             # Setup DNS
│   ├── setup-timezone.sh        # Setup múi giờ VN
│   ├── sync-time.sh             # Đồng bộ thời gian
│   ├── set-authkey.sh           # Cập nhật Auth Key
│   ├── restart-services.sh      # Restart dịch vụ
│   ├── check-and-restart.sh     # Auto-restart
│   └── uninstall.sh             # Gỡ cài đặt
│
├── etc/
│   ├── tailscale.conf           # Tailscale config
│   ├── ntp.conf                 # NTP config
│   ├── timezone                 # Múi giờ (Asia/Ho_Chi_Minh)
│   ├── crontab                  # CRON jobs
│   ├── profile                  # Environment variables
│   │
│   ├── AdGuardHome/
│   │   ├── AdGuardHome.yaml     # Main config
│   │   ├── AdGuardHome.db       # Filtering rules DB
│   │   └── data/                # Query logs, statistics
│   │
│   ├── init.d/
│   │   ├── S95ntp               # NTP init script
│   │   ├── S97adguardhome       # AdGuard Home init
│   │   ├── S98tailscaled        # tailscaled init
│   │   └── S99tailscale         # Tailscale init
│   │
│   ├── init.d/rc.d/             # Symlinks
│   │   ├── S95ntp -> ../S95ntp
│   │   ├── S97adguardhome -> ../S97adguardhome
│   │   ├── S98tailscaled -> ../S98tailscaled
│   │   └── S99tailscale -> ../S99tailscale
│   │
│   ├── ndm/netfilter.d/
│   │   └── 100-tailscale.sh     # Firewall rules
│   │
│   └── crontabs/
│       └── root                 # CRON table
│
└── var/
    ├── lib/
    │   ├── tailscale/
    │   │   └── tailscaled.state # Tailscale state
    │   └── ntp/
    │       └── ntp.drift        # NTP drift file
    │
    ├── run/
    │   ├── tailscaled.sock      # Tailscale socket
    │   ├── adguardhome.pid      # AdGuard PID
    │   └── tailscaled.pid       # tailscaled PID
    │
    └── log/
        ├── auto-restart.log     # Auto-restart events
        ├── restart-services.log # Restart logs
        ├── dns-setup.log        # DNS setup logs
        ├── ntp.log              # NTP logs
        ├── time-sync.log        # Time sync logs
        └── cron.log             # CRON logs

❓ Hỏi đáp
Q: Script có hỗ trợ Keenetic nào?

A: Hỗ trợ tất cả Keenetic chạy OS 3.7+ và có hỗ trợ Entware/OPKG:

    KN-1010, KN-2010, KN-3010

    Hopper, Giga, Titan

    Extra, Speedster, Ultra

Q: Làm thế nào để thay đổi subnet advertise?

A: Sửa file /opt/etc/tailscale.conf:
bash

export TS_ROUTES="192.168.1.0/24"  # Thay đổi thành subnet của bạn

Sau đó restart: /opt/etc/init.d/S99tailscale restart
Q: Tôi có thể chạy AdGuard Home trên port khác không?

A: Có, sửa file /opt/etc/AdGuardHome/AdGuardHome.yaml:
yaml

dns:
  port: 53  # Thay đổi thành port khác

Nhưng cần cập nhật DNS config tương ứng.
Q: Làm sao để biết Tailscale đang chạy?

A: Chạy lệnh:
bash

tailscale status
# Hoặc
/opt/etc/init.d/S99tailscale status

Q: Tôi có thể sử dụng Tailscale mà không cần Exit Node?

A: Có, sửa /opt/etc/tailscale.conf:
bash

export TS_EXIT_NODE="false"

Restart: /opt/etc/init.d/S99tailscale restart
Q: Backup và restore cấu hình?

A: Backup thư mục:
bash

# Backup
tar -czf backup-config.tar.gz /opt/etc/tailscale.conf /opt/etc/AdGuardHome/

# Restore
tar -xzf backup-config.tar.gz -C /

Q: Script có ảnh hưởng đến cấu hình Keenetic hiện tại?

A: Script chỉ thay đổi DNS settings và thêm firewall rules. Các cấu hình khác không bị ảnh hưởng.
Q: Làm sao để cập nhật AdGuard Home?

A:
bash

# Stop AdGuard
/opt/etc/init.d/S97adguardhome stop
# Update binary
opkg update && opkg upgrade adguardhome-go
# Start lại
/opt/etc/init.d/S97adguardhome start

Q: Tôi có thể chạy nhiều instance Tailscale không?

A: Không, Tailscale chỉ hỗ trợ một instance trên mỗi thiết bị.
📝 Changelog
v1.0 - Full với tự động phát hiện subnet (Current)

    ✅ Tự động phát hiện subnet LAN

    ✅ Hỗ trợ múi giờ Việt Nam (Asia/Ho_Chi_Minh)

    ✅ NTP servers cho Việt Nam

    ✅ Auto-restart service chết

    ✅ Script tương tác nhập Auth Key

    ✅ Logging đầy đủ

    ✅ CRON jobs tự động

    ✅ Fix DNS conflict tự động

    ✅ Uninstall script

    ✅ Thêm AdGuard Home DNS filtering

    ✅ Tích hợp NTP sync

    ✅ Auto-detect subnet

    ✅ Cài đặt Tailscale cơ bản

    ✅ Netfilter rules

    ✅ Init scripts

📜 Giấy phép

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
🤝 Đóng góp

Mọi đóng góp đều được chào đón!

    🐛 Báo lỗi: Tạo issue

    💡 Đề xuất tính năng: Tạo issue

    🔧 Pull requests: Luôn được xem xét

📞 Liên hệ và Hỗ trợ

    GitHub Issues: https://github.com/DKhoa25/keenetic-tailscale-adguard/issues

    Diễn đàn Keenetic: https://forum.keenetic.com/

    Tailscale Community: https://tailscale.com/community/

    AdGuard Home Support: https://github.com/AdguardTeam/AdGuardHome

<div align="center"> <sub>Built with ❤️ for the Keenetic Community</sub> </div> ```
