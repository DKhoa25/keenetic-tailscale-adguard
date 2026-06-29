#!/bin/sh
# ============================================
# Cài đặt Tailscale + AdGuard Home + NTP trên Keenetic
# Version: 1.0
# ============================================

echo "=== BAT DAU CAI DAT TAILSCALE & ADGUARD HOME & NTP ==="

# Kiểm tra quyền root
if [ "$(id -u)" != "0" ]; then
    echo "❌ LỖI: Script phải chạy với quyền root!"
    exit 1
fi

# Hàm kiểm tra lệnh thành công
check_success() {
    if [ $? -eq 0 ]; then
        echo "   ✅ Thành công"
    else
        echo "   ❌ Thất bại"
        return 1
    fi
}

# Hàm tự động phát hiện subnet
detect_subnet() {
    # Lấy IP của interface br0 (hoặc eth0, wlan0)
    local router_ip=$(ip addr show br0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    
    # Nếu không có br0, thử các interface khác
    if [ -z "$router_ip" ]; then
        router_ip=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    fi
    if [ -z "$router_ip" ]; then
        router_ip=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    fi
    if [ -z "$router_ip" ]; then
        router_ip=$(ip route | grep default | awk '{print $9}' | head -1)
    fi
    
    # Nếu vẫn không có, thử lấy từ default gateway
    if [ -z "$router_ip" ]; then
        router_ip=$(ip route | grep default | awk '{print $3}' | head -1)
    fi
    
    # Lấy subnet mask
    local subnet_mask=$(ip addr show br0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f2)
    if [ -z "$subnet_mask" ]; then
        subnet_mask="24" # Mặc định /24
    fi
    
    # Chuyển đổi IP thành subnet
    if [ -n "$router_ip" ]; then
        # Lấy 3 octet đầu của IP
        local subnet_base=$(echo "$router_ip" | cut -d. -f1-3)
        DETECTED_SUBNET="${subnet_base}.0/${subnet_mask}"
        DETECTED_IP="$router_ip"
        echo "   📍 Phát hiện IP router: $DETECTED_IP"
        echo "   📍 Phát hiện subnet: $DETECTED_SUBNET"
        return 0
    else
        echo "   ⚠️ Không thể phát hiện subnet, sử dụng mặc định: 192.168.1.0/24"
        DETECTED_SUBNET="192.168.1.0/24"
        DETECTED_IP="192.168.1.1"
        return 1
    fi
}

# Phát hiện subnet trước khi cài đặt
echo ""
echo "🔍 Đang phát hiện cấu hình mạng..."
detect_subnet

# 1. Cài đặt packages
echo ""
echo "📦 1. Cài đặt packages..."
opkg update
opkg install iptables tailscale ca-certificates adguardhome-go ntpclient
check_success

# 2. Tạo thư mục
echo ""
echo "📁 2. Tạo thư mục cần thiết..."
mkdir -p /opt/etc/ndm/netfilter.d
mkdir -p /opt/var/lib/tailscale
mkdir -p /opt/etc/init.d
mkdir -p /opt/var/run
mkdir -p /opt/bin
mkdir -p /opt/etc/AdGuardHome
mkdir -p /opt/etc/init.d/rc.d
mkdir -p /opt/var/log
mkdir -p /opt/etc/crontabs
mkdir -p /opt/var/lib/ntp
mkdir -p /opt/share/zoneinfo
check_success

# 3. Tạo netfilter script với subnet tự động
echo ""
echo "🔧 3. Tạo netfilter script..."
cat > /opt/etc/ndm/netfilter.d/100-tailscale.sh << 'EOF'
#!/bin/sh
# ============================================
# Tailscale Netfilter Hook - Keenetic
# ============================================

[ "$type" = "ip6tables" ] && exit 0

TAILSCALE_IP="100.86.208.78"
WAN_IF=$(ip route | grep default | awk '{print $5}' | head -1)

# Lấy IP của router trên tailscale nếu có
if [ -z "$TAILSCALE_IP" ]; then
    TAILSCALE_IP=$(ip addr show tailscale0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
fi

cleanup_chains() {
    iptables -D FORWARD -j ts-forward 2>/dev/null
    iptables -D INPUT -j ts-input 2>/dev/null
    iptables -F ts-forward 2>/dev/null
    iptables -F ts-input 2>/dev/null
    iptables -X ts-forward 2>/dev/null
    iptables -X ts-input 2>/dev/null
    iptables -t nat -D POSTROUTING -j ts-postrouting 2>/dev/null
    iptables -t nat -F ts-postrouting 2>/dev/null
    iptables -t nat -X ts-postrouting 2>/dev/null
}

setup_filter() {
    if ! ip link show tailscale0 >/dev/null 2>&1; then
        echo ">>> WARN: tailscale0 chua ton tai"
        return 1
    fi
    echo ">>> Dang cai dat filter rules..."
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Tạo chain ts-forward
    iptables -N ts-forward 2>/dev/null
    iptables -F ts-forward 2>/dev/null
    iptables -A ts-forward -i tailscale0 -j MARK --set-xmark 0x40000/0xff0000
    iptables -A ts-forward -m mark --mark 0x40000/0xff0000 -j ACCEPT
    iptables -A ts-forward -s 100.64.0.0/10 -o tailscale0 -j DROP
    iptables -A ts-forward -o tailscale0 -m conntrack ! --ctstate RELATED,ESTABLISHED -j DROP
    iptables -A ts-forward -o tailscale0 -j ACCEPT
    
    # Chèn vào FORWARD (kiểm tra tồn tại)
    iptables -D FORWARD -j ts-forward 2>/dev/null
    iptables -I FORWARD 1 -j ts-forward
    
    # Tạo chain ts-input
    iptables -N ts-input 2>/dev/null
    iptables -F ts-input 2>/dev/null
    if [ -n "$TAILSCALE_IP" ]; then
        iptables -A ts-input -s "$TAILSCALE_IP" -i lo -j ACCEPT
    fi
    iptables -A ts-input -s 100.115.92.0/23 ! -i tailscale0 -j RETURN
    iptables -A ts-input -s 100.64.0.0/10 ! -i tailscale0 -j DROP
    iptables -A ts-input -i tailscale0 -j ACCEPT
    iptables -A ts-input -p udp -m udp --dport 41641 -j ACCEPT
    
    # Chèn vào INPUT (kiểm tra tồn tại)
    iptables -D INPUT -j ts-input 2>/dev/null
    iptables -I INPUT 1 -j ts-input
    
    # Forward rules cơ bản
    iptables -D FORWARD -i tailscale0 -j ACCEPT 2>/dev/null
    iptables -D FORWARD -o tailscale0 -j ACCEPT 2>/dev/null
    iptables -I FORWARD -i tailscale0 -j ACCEPT
    iptables -I FORWARD -o tailscale0 -j ACCEPT
    
    echo ">>> Filter rules thanh cong!"
}

setup_nat() {
    echo ">>> Dang cai dat NAT rules..."
    
    # Tạo chain NAT
    iptables -t nat -N ts-postrouting 2>/dev/null
    iptables -t nat -F ts-postrouting 2>/dev/null
    iptables -t nat -A ts-postrouting -m mark --mark 0x40000/0xff0000 -j MASQUERADE
    
    # Chèn vào POSTROUTING (kiểm tra tồn tại)
    iptables -t nat -D POSTROUTING -j ts-postrouting 2>/dev/null
    iptables -t nat -I POSTROUTING 1 -j ts-postrouting
    
    if [ -n "$WAN_IF" ]; then
        echo ">>> WAN interface: $WAN_IF"
        iptables -t nat -D POSTROUTING -o "$WAN_IF" -j MASQUERADE 2>/dev/null
        iptables -t nat -I POSTROUTING -o "$WAN_IF" -j MASQUERADE
    else
        echo ">>> CANH BAO: Khong tim thay WAN interface!"
    fi
    echo ">>> NAT rules thanh cong!"
}

case "$table" in
    filter)
        cleanup_chains
        setup_filter
        ;;
    nat)
        cleanup_chains
        setup_nat
        ;;
    *)
        cleanup_chains
        setup_filter
        setup_nat
        ;;
esac

exit 0
EOF

chmod +x /opt/etc/ndm/netfilter.d/100-tailscale.sh
check_success

# 4. Tạo init script cho AdGuard Home
echo ""
echo "🚀 4. Tạo init script cho AdGuard Home..."
cat > /opt/etc/init.d/S97adguardhome << 'EOF'
#!/bin/sh

START=97
STOP=15
PIDFILE=/opt/var/run/adguardhome.pid
ADGUARD_BIN="/opt/bin/AdGuardHome"
ADGUARD_CONFIG="/opt/etc/AdGuardHome/AdGuardHome.yaml"

# Hàm kiểm tra port 53
check_port_53() {
    if netstat -tlnp 2>/dev/null | grep -q ":53 "; then
        echo "   ⚠️ Port 53 đang bị chiếm dụng"
        local pid=$(netstat -tlnp 2>/dev/null | grep ":53 " | awk '{print $7}' | cut -d'/' -f1)
        if [ -n "$pid" ]; then
            echo "   Killing process $pid đang dùng port 53..."
            kill -9 $pid 2>/dev/null
            sleep 2
        fi
    fi
}

start() {
    echo "Dang khoi dong AdGuard Home..."
    
    # Kill process cũ nếu còn
    pkill AdGuardHome 2>/dev/null
    sleep 1
    
    # Giải phóng port 53
    check_port_53
    
    # Cấu hình DNS cho Keenetic
    echo "Cau hinh DNS cho Keenetic..."
    
    # Tắt DNS server mặc định
    if command -v ndmc >/dev/null 2>&1; then
        ndmc -c "dns server disable" 2>/dev/null || true
        ndmc -c "dns forward 127.0.0.1" 2>/dev/null || true
        echo "   ✓ Da cau hinh DNS qua ndmc"
    else
        echo "   ⚠️ ndmc khong co san"
    fi
    
    # Tạo cấu hình DNS cho hệ thống
    mkdir -p /tmp/resolv.conf.d
    cat > /tmp/resolv.conf.d/head << 'DNS_CONFIG'
nameserver 127.0.0.1
options ndots:0
DNS_CONFIG
    echo "   ✓ Da tao cau hinh DNS he thong"
    
    # Backup DNS config cu
    if [ -f /etc/resolv.conf ] && [ ! -f /etc/resolv.conf.backup ]; then
        cp /etc/resolv.conf /etc/resolv.conf.backup
    fi
    
    # Kiểm tra config file
    if [ ! -f "$ADGUARD_CONFIG" ]; then
        echo "   ⚠️ AdGuard Home chua duoc cau hinh!"
        echo "   Vui long truy cap http://$(ip addr show br0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1):3000 de thiet lap"
    fi
    
    # Kiểm tra binary
    if [ ! -f "$ADGUARD_BIN" ]; then
        echo "   ❌ Khong tim thay binary AdGuard Home tai $ADGUARD_BIN"
        echo "   Thu tim trong PATH..."
        ADGUARD_BIN=$(which AdGuardHome 2>/dev/null)
        if [ -z "$ADGUARD_BIN" ]; then
            echo "   ❌ Khong tim thay AdGuardHome"
            return 1
        fi
    fi
    
    # Khởi động AdGuard Home
    echo "   Khoi dong AdGuard Home tu: $ADGUARD_BIN"
    $ADGUARD_BIN -s run > /tmp/adguardhome.log 2>&1 &
    echo $! > $PIDFILE
    
    sleep 5
    
    # Kiểm tra đã chạy chưa
    if pgrep AdGuardHome >/dev/null; then
        echo "   ✅ AdGuard Home da khoi dong (PID: $(cat $PIDFILE))"
        local ip=$(ip addr show br0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        echo "   🌐 Web interface: http://${ip:-localhost}:3000"
        echo "   🔧 DNS Server: 127.0.0.1:53"
        
        # Kiểm tra DNS hoạt động
        if command -v nslookup >/dev/null; then
            if nslookup google.com 127.0.0.1 >/dev/null 2>&1; then
                echo "   ✅ DNS test thanh cong"
            else
                echo "   ⚠️ DNS test that bai, kiem tra log: /tmp/adguardhome.log"
            fi
        fi
        return 0
    else
        echo "   ❌ AdGuard Home khong khoi dong duoc"
        echo "   Log:"
        cat /tmp/adguardhome.log 2>/dev/null | tail -10
        return 1
    fi
}

stop() {
    echo "Dang dung AdGuard Home..."
    if [ -f $PIDFILE ]; then
        kill -TERM $(cat $PIDFILE) 2>/dev/null
        rm -f $PIDFILE
    else
        pkill AdGuardHome 2>/dev/null
    fi
    
    sleep 2
    
    # Restore DNS config
    if command -v ndmc >/dev/null 2>&1; then
        ndmc -c "dns server enable" 2>/dev/null || true
        ndmc -c "dns forward off" 2>/dev/null || true
    fi
    
    if [ -f /etc/resolv.conf.backup ]; then
        cp /etc/resolv.conf.backup /etc/resolv.conf
    fi
    
    echo "   ✅ AdGuard Home da dung"
}

status() {
    if pgrep AdGuardHome >/dev/null; then
        echo "   ✅ AdGuard Home dang chay"
        echo "   PID: $(pgrep AdGuardHome)"
        echo "   DNS: $(netstat -tlnp 2>/dev/null | grep :53 | grep AdGuardHome | head -1)"
    else
        echo "   ❌ AdGuard Home khong chay"
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 3
        start
        ;;
    status)
        status
        ;;
    *)
        echo "Cach dung: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
EOF

chmod +x /opt/etc/init.d/S97adguardhome
check_success

# 5. Tạo init script cho tailscaled
echo ""
echo "🚀 5. Tạo init script cho tailscaled..."
cat > /opt/etc/init.d/S98tailscaled << 'EOF'
#!/bin/sh

START=98
STOP=20
PIDFILE=/opt/var/run/tailscaled.pid
TAILSCALED_BIN="/opt/bin/tailscaled"

start() {
    echo "Dang khoi dong tailscaled..."
    mkdir -p /opt/var/lib/tailscale
    mkdir -p /opt/var/run
    
    # Kill process cu
    pkill tailscaled 2>/dev/null
    sleep 1
    
    # Kiểm tra binary
    if [ ! -f "$TAILSCALED_BIN" ]; then
        TAILSCALED_BIN=$(which tailscaled 2>/dev/null)
        if [ -z "$TAILSCALED_BIN" ]; then
            echo "   ❌ Khong tim thay tailscaled"
            return 1
        fi
    fi
    
    # Khởi động tailscaled
    $TAILSCALED_BIN \
        --port 41641 \
        --state=/opt/var/lib/tailscale/tailscaled.state \
        --socket=/opt/var/run/tailscaled.sock \
        > /tmp/tailscaled.log 2>&1 &
    
    sleep 5
    
    if pgrep tailscaled >/dev/null; then
        local pid=$(pgrep tailscaled)
        echo $pid > $PIDFILE
        echo "   ✅ tailscaled da khoi dong (PID: $pid)"
        return 0
    else
        echo "   ❌ tailscaled khong khoi dong duoc"
        echo "   Log:"
        cat /tmp/tailscaled.log 2>/dev/null | tail -10
        return 1
    fi
}

stop() {
    echo "Dang dung tailscaled..."
    pkill tailscaled 2>/dev/null
    rm -f $PIDFILE
    echo "   ✅ tailscaled da dung"
}

status() {
    if pgrep tailscaled >/dev/null; then
        echo "   ✅ tailscaled dang chay (PID: $(pgrep tailscaled))"
    else
        echo "   ❌ tailscaled khong chay"
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 2
        start
        ;;
    status)
        status
        ;;
    *)
        echo "Cach dung: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
EOF

chmod +x /opt/etc/init.d/S98tailscaled
check_success

# 6. Tạo init script cho tailscale (có tương tác auth key và subnet tự động)
echo ""
echo "🚀 6. Tạo init script cho tailscale..."

# Lấy subnet đã phát hiện
if [ -z "$DETECTED_SUBNET" ]; then
    detect_subnet
fi

cat > /opt/etc/init.d/S99tailscale << EOF
#!/bin/sh

START=99
STOP=10

# Load config
if [ -f /opt/etc/tailscale.conf ]; then
    . /opt/etc/tailscale.conf
fi

# Default values
TS_AUTHKEY="\${TS_AUTHKEY:-}"
TS_OPTS="--accept-dns=false --netfilter-mode=off"
TS_ROUTES="\${TS_ROUTES:-$DETECTED_SUBNET}"
TS_EXIT_NODE="\${TS_EXIT_NODE:-true}"
TS_SSH="\${TS_SSH:-true}"

# Build options
if [ -n "\$TS_ROUTES" ]; then
    TS_OPTS="\$TS_OPTS --advertise-routes=\$TS_ROUTES"
fi
if [ "\$TS_EXIT_NODE" = "true" ]; then
    TS_OPTS="\$TS_OPTS --advertise-exit-node"
fi
if [ "\$TS_SSH" = "true" ]; then
    TS_OPTS="\$TS_OPTS --ssh"
fi

# Hàm nhập auth key tương tác
get_auth_key() {
    echo ""
    echo "=========================================="
    echo "🔑 TAILSCALE AUTHENTICATION REQUIRED"
    echo "=========================================="
    echo "Vui lòng nhập Tailscale Auth Key"
    echo "Lấy tại: https://login.tailscale.com/admin/settings/keys"
    echo ""
    echo "Nhập auth key (hoặc nhấn Enter để bỏ qua):"
    read -r AUTHKEY_INPUT
    
    if [ -n "\$AUTHKEY_INPUT" ]; then
        # Lưu vào config file
        if [ -f /opt/etc/tailscale.conf ]; then
            sed -i "s/export TS_AUTHKEY=.*/export TS_AUTHKEY=\"\$AUTHKEY_INPUT\"/" /opt/etc/tailscale.conf
        else
            echo "export TS_AUTHKEY=\"\$AUTHKEY_INPUT\"" > /opt/etc/tailscale.conf
        fi
        export TS_AUTHKEY="\$AUTHKEY_INPUT"
        echo "   ✅ Đã lưu auth key"
        return 0
    else
        echo "   ⚠️ Bỏ qua, không có auth key"
        return 1
    fi
}

start() {
    echo "Dang khoi dong Tailscale..."
    
    # Bật IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo 1 > /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || true
    
    # Kiểm tra và khởi động AdGuard Home trước
    if ! pgrep AdGuardHome >/dev/null; then
        echo "   ⚠️ AdGuard Home chua chay, khoi dong truoc..."
        /opt/etc/init.d/S97adguardhome start || {
            echo "   ❌ Khong the khoi dong AdGuard Home"
            return 1
        }
        sleep 3
    fi
    
    # Kiểm tra tailscaled
    if ! pgrep tailscaled >/dev/null; then
        echo "   ⚠️ tailscaled chua chay, dang khoi dong..."
        /opt/etc/init.d/S98tailscaled start || {
            echo "   ❌ Khong the khoi dong tailscaled"
            return 1
        }
        sleep 3
    fi
    
    # Wait for tailscaled socket
    local max_attempts=10
    local attempt=0
    while [ ! -S /opt/var/run/tailscaled.sock ] && [ \$attempt -lt \$max_attempts ]; do
        sleep 1
        attempt=\$((attempt + 1))
    done
    
    # Check if already logged in
    local status_output=\$(tailscale status 2>/dev/null)
    if echo "\$status_output" | grep -q "Logged out"; then
        echo "   🔑 Dang login Tailscale..."
        
        # Nếu chưa có auth key, yêu cầu nhập
        if [ -z "\$TS_AUTHKEY" ]; then
            echo "   ⚠️ Chưa có Auth Key!"
            if get_auth_key; then
                # Reload auth key
                if [ -f /opt/etc/tailscale.conf ]; then
                    . /opt/etc/tailscale.conf
                fi
            else
                echo "   ❌ Không có auth key, không thể login"
                echo "   Vui lòng chạy lệnh sau để login:"
                echo "   tailscale up --authkey=YOUR_AUTH_KEY \$TS_OPTS"
                return 1
            fi
        fi
        
        # Thử login với auth key
        if [ -n "\$TS_AUTHKEY" ]; then
            echo "   Đang login với auth key..."
            tailscale up --authkey="\$TS_AUTHKEY" \$TS_OPTS
            if [ \$? -ne 0 ]; then
                echo "   ❌ Login thất bại! Auth key không hợp lệ hoặc hết hạn"
                echo "   Vui lòng nhập auth key mới:"
                if get_auth_key; then
                    . /opt/etc/tailscale.conf
                    tailscale up --authkey="\$TS_AUTHKEY" \$TS_OPTS
                fi
            fi
        fi
    else
        echo "   🔄 Tailscale da login, cap nhat cau hinh..."
        tailscale up \$TS_OPTS
    fi
    
    sleep 3
    
    # Chạy netfilter script
    if [ -x /opt/etc/ndm/netfilter.d/100-tailscale.sh ]; then
        echo "   🔧 Chay netfilter script..."
        /opt/etc/ndm/netfilter.d/100-tailscale.sh
    else
        echo "   ⚠️ Khong tim thay netfilter script"
    fi
    
    # Hiển thị thông tin
    local ip=\$(ip addr show tailscale0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
    if [ -n "\$ip" ]; then
        echo "   ✅ Tailscale da khoi dong voi IP: \$ip"
        if [ "\$TS_EXIT_NODE" = "true" ]; then
            echo "   ✅ Exit Node da duoc BAT"
        fi
        echo ""
        echo "   📋 Tailscale Status:"
        tailscale status | head -5
    else
        echo "   ❌ Tailscale co the chua san sang"
        echo "   Log:"
        tailscale status
        return 1
    fi
}

stop() {
    echo "Dang dung Tailscale..."
    tailscale down 2>/dev/null
    echo "   ✅ Tailscale da dung"
}

status() {
    if pgrep tailscaled >/dev/null; then
        echo "   ✅ Tailscale dang chay"
        echo ""
        tailscale status
        echo ""
        echo "   --- Interfaces ---"
        ip addr show tailscale0 2>/dev/null || echo "   tailscale0 chua ton tai"
    else
        echo "   ❌ Tailscale khong chay"
    fi
}

case "\$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 3
        start
        ;;
    status)
        status
        ;;
    *)
        echo "Cach dung: \$0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
EOF

chmod +x /opt/etc/init.d/S99tailscale
check_success

# 7. Tạo file cấu hình authkey với subnet tự động
echo ""
echo "🔑 7. Cấu hình Tailscale với subnet: $DETECTED_SUBNET"

# Hỏi người dùng nhập auth key
echo ""
echo "=========================================="
echo "VUI LÒNG NHẬP TAILSCALE AUTH KEY"
echo "=========================================="
echo "Lấy auth key tại: https://login.tailscale.com/admin/settings/keys"
echo ""
echo "Nhập auth key (hoặc để trống để nhập sau):"
read -r TS_AUTHKEY_INPUT

# Tạo file cấu hình với subnet đã phát hiện
cat > /opt/etc/tailscale.conf << EOF
# Tailscale Configuration
# ========================

# Auth key từ Tailscale Admin Console
# Tạo tại: https://login.tailscale.com/admin/settings/keys
export TS_AUTHKEY="${TS_AUTHKEY_INPUT}"

# Cấu hình mạng (Tự động phát hiện)
export TS_ROUTES="${DETECTED_SUBNET}"        # Subnet muốn advertise
export TS_EXIT_NODE="true"                # Bật Exit Node
export TS_SSH="true"                       # Bật SSH qua Tailscale

# Không sửa các dòng bên dưới
export TS_ACCEPT_DNS="false"
export TS_NETFILTER_MODE="off"
EOF

chmod 600 /opt/etc/tailscale.conf

if [ -n "$TS_AUTHKEY_INPUT" ]; then
    echo "   ✅ Đã lưu auth key"
else
    echo "   ⚠️ Bạn để trống auth key, sẽ nhập sau khi chạy Tailscale"
fi
check_success

# 8. Cấu hình NTP và múi giờ Việt Nam
echo ""
echo "🕐 8. Cấu hình NTP và múi giờ Việt Nam..."

# Tạo script cấu hình múi giờ
cat > /opt/bin/setup-timezone.sh << 'EOF'
#!/bin/sh
# ============================================
# Cấu hình múi giờ Việt Nam và NTP
# ============================================

LOG_FILE="/opt/var/log/timezone-setup.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[$DATE] $1" >> $LOG_FILE
}

echo "=== CẤU HÌNH MÚI GIỜ VIỆT NAM ==="

# 1. Cấu hình múi giờ
echo "1. Cấu hình múi giờ Asia/Ho_Chi_Minh..."

# Tạo file cấu hình múi giờ
cat > /opt/etc/timezone << 'TZ_CONFIG'
Asia/Ho_Chi_Minh
TZ_CONFIG

# Tạo symlink cho localtime
ln -sf /opt/share/zoneinfo/Asia/Ho_Chi_Minh /opt/etc/localtime 2>/dev/null || \
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime 2>/dev/null

# Export biến môi trường
export TZ='Asia/Ho_Chi_Minh'

# Thêm vào profile
if ! grep -q "TZ=Asia/Ho_Chi_Minh" /opt/etc/profile 2>/dev/null; then
    echo "export TZ='Asia/Ho_Chi_Minh'" >> /opt/etc/profile
fi

# Kiểm tra múi giờ
CURRENT_TZ=$(date +%Z)
echo "   ✅ Múi giờ hiện tại: $CURRENT_TZ"
echo "   ✅ Thời gian hiện tại: $(date '+%Y-%m-%d %H:%M:%S %Z')"

# 2. Cấu hình NTP
echo ""
echo "2. Cấu hình NTP..."

# Tạo file cấu hình NTP cho Việt Nam
cat > /opt/etc/ntp.conf << 'NTP_CONFIG'
# NTP Servers cho Việt Nam và Đông Nam Á
server 0.vn.pool.ntp.org iburst
server 1.vn.pool.ntp.org iburst
server 2.vn.pool.ntp.org iburst
server 3.vn.pool.ntp.org iburst

# Dự phòng các server gần nhất
server 0.asia.pool.ntp.org iburst
server 1.asia.pool.ntp.org iburst
server 2.asia.pool.ntp.org iburst

# Cấu hình chung
driftfile /opt/var/lib/ntp/ntp.drift
logfile /opt/var/log/ntp.log

# Giới hạn truy cập
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict -6 ::1
NTP_CONFIG

# Tạo thư mục cho NTP
mkdir -p /opt/var/lib/ntp
mkdir -p /opt/var/log

# 3. Tạo script đồng bộ thời gian
cat > /opt/bin/sync-time.sh << 'SYNC_SCRIPT'
#!/bin/sh
# ============================================
# Đồng bộ thời gian với NTP Server
# ============================================

LOG_FILE="/opt/var/log/time-sync.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[$DATE] $1" >> $LOG_FILE
}

echo "=== ĐỒNG BỘ THỜI GIAN ==="

# Kiểm tra kết nối internet
if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "   ⚠️ Không có kết nối internet, bỏ qua đồng bộ"
    log "WARN: No internet connection"
    exit 1
fi

# Đồng bộ thời gian
if command -v ntpdate >/dev/null 2>&1; then
    echo "   Đồng bộ qua ntpdate..."
    ntpdate -u 0.vn.pool.ntp.org 2>&1 | tee -a $LOG_FILE
elif command -v ntpd >/dev/null 2>&1; then
    echo "   Đồng bộ qua ntpd..."
    ntpd -q -g -c /opt/etc/ntp.conf 2>&1 | tee -a $LOG_FILE
elif command -v chronyc >/dev/null 2>&1; then
    echo "   Đồng bộ qua chrony..."
    chronyc -a makestep 2>&1 | tee -a $LOG_FILE
else
    echo "   ⚠️ Không tìm thấy NTP client"
    # Thử đồng bộ qua busybox
    if command -v busybox >/dev/null 2>&1; then
        busybox ntpdate -u 0.vn.pool.ntp.org 2>&1 | tee -a $LOG_FILE
    fi
fi

# Cập nhật thời gian hardware clock nếu có
if command -v hwclock >/dev/null 2>&1; then
    hwclock --systohc 2>/dev/null && echo "   ✅ Đã cập nhật hardware clock"
fi

# Kiểm tra kết quả
NEW_TIME=$(date '+%Y-%m-%d %H:%M:%S %Z')
echo "   ✅ Thời gian sau đồng bộ: $NEW_TIME"
log "Sync completed: $NEW_TIME"

# Hiển thị chênh lệch thời gian
if [ -f /opt/var/lib/ntp/ntp.drift ]; then
    DRIFT=$(cat /opt/var/lib/ntp/ntp.drift 2>/dev/null)
    echo "   📊 Drift: $DRIFT ppm"
fi

echo ""
echo "✅ Đồng bộ thời gian hoàn tất"
SYNC_SCRIPT

chmod +x /opt/bin/sync-time.sh

# 4. Tạo init script cho NTP
cat > /opt/etc/init.d/S95ntp << 'NTP_INIT'
#!/bin/sh

START=95
STOP=10
PIDFILE=/opt/var/run/ntpd.pid

start() {
    echo "Đang khởi động NTP..."
    
    # Kiểm tra và tạo thư mục
    mkdir -p /opt/var/lib/ntp
    mkdir -p /opt/var/log
    
    # Đồng bộ thời gian lần đầu
    echo "   Đồng bộ thời gian lần đầu..."
    /opt/bin/sync-time.sh
    
    # Khởi động NTP daemon nếu có
    if command -v ntpd >/dev/null 2>&1; then
        echo "   Khởi động ntpd daemon..."
        ntpd -g -c /opt/etc/ntp.conf -p /opt/var/run/ntpd.pid
        sleep 2
        if pgrep ntpd >/dev/null; then
            echo "   ✅ NTP daemon đã khởi động (PID: $(pgrep ntpd))"
        else
            echo "   ⚠️ Không thể khởi động ntpd daemon"
        fi
    elif command -v chronyd >/dev/null 2>&1; then
        echo "   Khởi động chronyd daemon..."
        chronyd -f /opt/etc/ntp.conf
        sleep 2
        if pgrep chronyd >/dev/null; then
            echo "   ✅ Chrony daemon đã khởi động (PID: $(pgrep chronyd))"
        else
            echo "   ⚠️ Không thể khởi động chronyd daemon"
        fi
    else
        echo "   ⚠️ Không có NTP daemon, chỉ đồng bộ định kỳ qua cron"
    fi
}

stop() {
    echo "Đang dừng NTP..."
    pkill ntpd 2>/dev/null
    pkill chronyd 2>/dev/null
    rm -f $PIDFILE
    echo "   ✅ NTP đã dừng"
}

status() {
    if pgrep ntpd >/dev/null || pgrep chronyd >/dev/null; then
        echo "   ✅ NTP đang chạy"
        echo "   Thời gian hiện tại: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    else
        echo "   ❌ NTP không chạy"
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 2
        start
        ;;
    status)
        status
        ;;
    *)
        echo "Cách dùng: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
NTP_INIT

chmod +x /opt/etc/init.d/S95ntp

# 5. Cập nhật CRON với sync time
echo ""
echo "5. Cập nhật CRON với đồng bộ thời gian..."

# Backup và cập nhật crontab
if [ -f /opt/etc/crontab ]; then
    cp /opt/etc/crontab /opt/etc/crontab.bak
fi

# Thêm các job đồng bộ thời gian
cat >> /opt/etc/crontab << 'CRON_NTP'
# Đồng bộ thời gian mỗi 6 tiếng
0 */6 * * * /opt/bin/sync-time.sh

# Đồng bộ thời gian sau reboot
@reboot /opt/bin/sync-time.sh

# Cập nhật hardware clock mỗi ngày
0 3 * * * /opt/bin/sync-time.sh && hwclock --systohc 2>/dev/null
CRON_NTP

echo ""
echo "✅ Cấu hình NTP và múi giờ Việt Nam hoàn tất!"
echo "   📍 Múi giờ: $(date '+%Z')"
echo "   🕐 Thời gian: $(date '+%Y-%m-%d %H:%M:%S')"

log "Timezone and NTP setup completed"
EOF

chmod +x /opt/bin/setup-timezone.sh

# Chạy script cấu hình múi giờ
/opt/bin/setup-timezone.sh
check_success

# 9. Tạo sysctl.conf
echo ""
echo "⚙️ 9. Tạo sysctl.conf..."
cat > /opt/etc/sysctl.conf << 'EOF'
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
check_success

# 10. Tạo script fix DNS conflict
echo ""
echo "🔧 10. Tạo script fix DNS conflict..."
cat > /opt/bin/fix-dns-conflict.sh << 'EOF'
#!/bin/sh
# ============================================
# Fix DNS Conflict for AdGuard Home on Keenetic
# ============================================

echo "=== FIX DNS CONFLICT ==="

# 1. Kill process đang dùng port 53
echo "1. Kiem tra port 53..."
if netstat -tlnp 2>/dev/null | grep -q ":53 "; then
    echo "   ⚠️ Port 53 dang bi chiem dung"
    local pids=$(netstat -tlnp 2>/dev/null | grep ":53 " | awk '{print $7}' | cut -d'/' -f1)
    for pid in $pids; do
        if [ -n "$pid" ] && [ "$pid" != "$$" ]; then
            echo "   Killing process $pid..."
            kill -9 $pid 2>/dev/null
        fi
    done
    sleep 2
fi

# 2. Tắt DNS server mặc định của Keenetic
echo "2. Cau hinh DNS cho Keenetic..."
if command -v ndmc >/dev/null 2>&1; then
    ndmc -c "dns server disable" 2>/dev/null && echo "   ✅ Da tat DNS server" || echo "   ⚠️ Khong the tat DNS server"
    ndmc -c "dns forward 127.0.0.1" 2>/dev/null && echo "   ✅ Da cau hinh DNS forward" || echo "   ⚠️ Khong the cau hinh DNS forward"
else
    echo "   ❌ ndmc khong co san"
fi

# 3. Cấu hình DNS cho hệ thống
echo "3. Cau hinh DNS cho he thong..."
mkdir -p /tmp/resolv.conf.d
cat > /tmp/resolv.conf.d/head << 'DNS_CONFIG'
nameserver 127.0.0.1
options ndots:0
DNS_CONFIG
echo "   ✅ Da tao /tmp/resolv.conf.d/head"

# 4. Kiểm tra AdGuard Home
echo "4. Kiem tra AdGuard Home..."
if pgrep AdGuardHome >/dev/null; then
    echo "   ✅ AdGuard Home dang chay"
else
    echo "   ⚠️ AdGuard Home khong chay, khoi dong..."
    /opt/etc/init.d/S97adguardhome start
fi

sleep 2

# 5. Kiểm tra DNS
echo "5. Kiem tra DNS..."
if command -v nslookup >/dev/null; then
    if nslookup google.com 127.0.0.1 2>/dev/null | head -5; then
        echo "   ✅ DNS test thanh cong"
    else
        echo "   ❌ DNS test that bai"
    fi
else
    echo "   ⚠️ nslookup khong co san"
fi

echo ""
echo "✅ DNS Conflict da duoc fix"
local ip=$(ip addr show br0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
echo "   AdGuard Home dang lang nghe o port 53"
echo "   Web interface: http://${ip:-localhost}:3000"
EOF

chmod +x /opt/bin/fix-dns-conflict.sh
check_success

# 11. Tạo script setup DNS
echo ""
echo "🔧 11. Tạo script setup DNS..."
cat > /opt/bin/setup-dns.sh << 'EOF'
#!/bin/sh
# ============================================
# Cấu hình DNS tự động cho Keenetic
# ============================================

LOG_FILE="/opt/var/log/dns-setup.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Bat dau setup DNS" >> $LOG_FILE

# Đợi network ready
sleep 5

# Kiểm tra và kill process dùng port 53
if netstat -tlnp 2>/dev/null | grep -q ":53 "; then
    echo "   Killing process dang dung port 53..."
    pkill -f "dnsmasq" 2>/dev/null
    pkill -f "unbound" 2>/dev/null
    pkill -f "named" 2>/dev/null
    sleep 2
fi

# Tắt DNS server mặc định
if command -v ndmc >/dev/null 2>&1; then
    ndmc -c "dns server disable" 2>/dev/null
    ndmc -c "dns forward 127.0.0.1" 2>/dev/null
    echo "   ✅ DNS config via ndmc" >> $LOG_FILE
fi

# Tạo resolv.conf
mkdir -p /tmp/resolv.conf.d
cat > /tmp/resolv.conf.d/head << 'DNS'
nameserver 127.0.0.1
options ndots:0
DNS
echo "   ✅ Created /tmp/resolv.conf.d/head" >> $LOG_FILE

# Restart AdGuard Home
if pgrep AdGuardHome >/dev/null; then
    /opt/etc/init.d/S97adguardhome restart >> $LOG_FILE 2>&1
else
    /opt/etc/init.d/S97adguardhome start >> $LOG_FILE 2>&1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] DNS setup completed" >> $LOG_FILE
echo "✅ DNS setup hoan tat"
EOF

chmod +x /opt/bin/setup-dns.sh
check_success

# 12. Tạo script start-all
echo ""
echo "🚀 12. Tạo script start-all..."
cat > /opt/bin/start-all.sh << 'EOF'
#!/bin/sh
echo "=== KHOI DONG TOAN BO DICH VU ==="
echo ""

# Kiểm tra auth key
if [ -f /opt/etc/tailscale.conf ]; then
    . /opt/etc/tailscale.conf
    if [ -z "$TS_AUTHKEY" ]; then
        echo "⚠️ Chưa có Tailscale Auth Key!"
        echo ""
        echo "Vui lòng nhập Auth Key (hoặc để trống để bỏ qua):"
        read -r AUTHKEY
        if [ -n "$AUTHKEY" ]; then
            sed -i "s/export TS_AUTHKEY=.*/export TS_AUTHKEY=\"$AUTHKEY\"/" /opt/etc/tailscale.conf
            echo "   ✅ Đã lưu auth key"
        else
            echo "   ⚠️ Bỏ qua, Tailscale sẽ không tự động login"
        fi
    fi
fi

# Fix DNS trước
echo "📌 Cau hinh DNS truoc khi khoi dong..."
/opt/bin/setup-dns.sh
sleep 2

echo ""
echo "📌 Khoi dong NTP..."
/opt/etc/init.d/S95ntp start
sleep 2

echo ""
echo "📌 Khoi dong AdGuard Home..."
/opt/etc/init.d/S97adguardhome start
sleep 3

echo ""
echo "📌 Khoi dong tailscaled..."
/opt/etc/init.d/S98tailscaled start
sleep 3

echo ""
echo "📌 Khoi dong Tailscale..."
/opt/etc/init.d/S99tailscale start
sleep 3

# Khởi động CRON
echo ""
echo "📌 Khoi dong CRON..."
if ! pgrep crond >/dev/null; then
    crond -c /opt/etc/crontabs -L /opt/var/log/cron.log
    echo "   ✅ CRON da khoi dong"
else
    echo "   ✅ CRON da chay"
fi

echo ""
/opt/bin/check-all.sh
EOF

chmod +x /opt/bin/start-all.sh
check_success

# 13. Tạo script check-all
echo ""
echo "🔍 13. Tạo script kiểm tra tổng hợp..."
cat > /opt/bin/check-all.sh << 'EOF'
#!/bin/sh
echo "========================================"
echo "   TAILSCALE & ADGUARD HOME CHECK"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo ""
echo "1. ADGUARD HOME STATUS:"
echo "------------------------"
if pgrep AdGuardHome >/dev/null; then
    check_ok "AdGuard Home dang chay"
    echo "  PID: $(pgrep AdGuardHome)"
    echo "  Port: $(netstat -tlnp 2>/dev/null | grep AdGuardHome | awk '{print "    "$4}')"
else
    check_fail "AdGuard Home khong chay"
fi

echo ""
echo "2. TAILSCALE STATUS:"
echo "------------------------"
if pgrep tailscaled >/dev/null; then
    check_ok "Tailscale dang chay"
    echo ""
    tailscale status
    echo ""
    echo "Interface:"
    ip addr show tailscale0 2>/dev/null | grep 'inet ' || echo "  tailscale0 chua ton tai"
else
    check_fail "Tailscale khong chay"
fi

echo ""
echo "3. DNS CONFIG:"
echo "------------------------"
echo "--- /tmp/resolv.conf.d/head ---"
cat /tmp/resolv.conf.d/head 2>/dev/null || echo "Khong co DNS config"

echo ""
echo "--- DNS Test ---"
if command -v nslookup >/dev/null; then
    if nslookup google.com 127.0.0.1 >/dev/null 2>&1; then
        check_ok "DNS test thanh cong"
    else
        check_fail "DNS test that bai"
    fi
fi

echo ""
echo "4. IP FORWARDING:"
echo "------------------------"
if [ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)" = "1" ]; then
    check_ok "IP Forward: enabled"
else
    check_fail "IP Forward: disabled"
fi

echo ""
echo "5. FIREWALL RULES:"
echo "------------------------"
iptables -L FORWARD | grep -E "tailscale|ts-" | head -5 || echo "Khong co rule tailscale trong FORWARD"

echo ""
echo "6. NTP STATUS:"
echo "------------------------"
if pgrep ntpd >/dev/null || pgrep chronyd >/dev/null; then
    check_ok "NTP dang chay"
    echo "  Thoi gian: $(date '+%Y-%m-%d %H:%M:%S %Z')"
else
    check_warn "NTP khong chay (sync qua cron)"
fi

echo ""
echo "7. PROCESSES:"
echo "------------------------"
ps | grep -E "tailscale|AdGuardHome|crond|ntpd" | grep -v grep

echo ""
echo "========================================"
echo "📋 LOG FILES:"
echo "  /opt/var/log/restart-services.log  - Restart log"
echo "  /opt/var/log/auto-restart.log      - Auto-restart log"
echo "  /opt/var/log/cron.log              - Cron log"
echo "  /opt/var/log/dns-setup.log         - DNS setup log"
echo "  /opt/var/log/ntp.log               - NTP log"
echo "========================================"
EOF

chmod +x /opt/bin/check-all.sh
check_success

# 14. Tạo script restart-services
echo ""
echo "🔄 14. Tạo script restart-services..."
cat > /opt/bin/restart-services.sh << 'EOF'
#!/bin/sh
# ============================================
# Restart Tailscale & AdGuard Home
# ============================================

LOG_FILE="/opt/var/log/restart-services.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[$DATE] $1" >> $LOG_FILE
}

log "========== BAT DAU RESTART DICH VU =========="

# Fix DNS trước
log "Fix DNS config..."
/opt/bin/setup-dns.sh >> $LOG_FILE 2>&1
sleep 2

# Restart AdGuard Home
log "Restarting AdGuard Home..."
if pgrep AdGuardHome >/dev/null; then
    /opt/etc/init.d/S97adguardhome restart >> $LOG_FILE 2>&1
else
    /opt/etc/init.d/S97adguardhome start >> $LOG_FILE 2>&1
fi

sleep 5

# Restart Tailscale
log "Restarting Tailscale..."
if pgrep tailscaled >/dev/null; then
    /opt/etc/init.d/S99tailscale restart >> $LOG_FILE 2>&1
else
    /opt/etc/init.d/S99tailscale start >> $LOG_FILE 2>&1
fi

log "========== HOAN TAT RESTART =========="
echo ""

# Giới hạn log file (giữ 1000 dòng)
tail -n 1000 $LOG_FILE > /tmp/restart-services.tmp
mv /tmp/restart-services.tmp $LOG_FILE

echo "✅ Restart hoan tat luc $(date '+%H:%M:%S')"
EOF

chmod +x /opt/bin/restart-services.sh
check_success

# 15. Tạo script check-and-restart
echo ""
echo "🔍 15. Tạo script check-and-restart..."
cat > /opt/bin/check-and-restart.sh << 'EOF'
#!/bin/sh
# ============================================
# Kiểm tra và tự động restart nếu service chết
# ============================================

LOG_FILE="/opt/var/log/auto-restart.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[$DATE] $1" >> $LOG_FILE
}

# Kiểm tra DNS config
if ! grep -q "nameserver 127.0.0.1" /tmp/resolv.conf.d/head 2>/dev/null; then
    log "⚠️ DNS config bi mat, dang cau hinh lai..."
    /opt/bin/setup-dns.sh >> $LOG_FILE 2>&1
fi

# Kiểm tra AdGuard Home
if ! pgrep AdGuardHome >/dev/null; then
    log "⚠️ AdGuard Home khong chay, dang khoi dong lai..."
    /opt/etc/init.d/S97adguardhome start >> $LOG_FILE 2>&1
fi

# Kiểm tra Tailscale
if ! pgrep tailscaled >/dev/null; then
    log "⚠️ Tailscale khong chay, dang khoi dong lai..."
    /opt/etc/init.d/S99tailscale start >> $LOG_FILE 2>&1
else
    # Kiểm tra đã login chưa
    if tailscale status 2>/dev/null | grep -q "Logged out"; then
        log "⚠️ Tailscale chua login, dang login..."
        if [ -f /opt/etc/tailscale.conf ]; then
            . /opt/etc/tailscale.conf
            if [ -n "$TS_AUTHKEY" ]; then
                tailscale up --authkey="$TS_AUTHKEY" --accept-dns=false --netfilter-mode=off --advertise-routes="$TS_ROUTES" --advertise-exit-node --ssh
            fi
        fi
    fi
fi

# Giới hạn log file
tail -n 500 $LOG_FILE > /tmp/auto-restart.tmp
mv /tmp/auto-restart.tmp $LOG_FILE
EOF

chmod +x /opt/bin/check-and-restart.sh
check_success

# 16. Tạo script nhập auth key
echo ""
echo "🔑 16. Tạo script nhập auth key..."
cat > /opt/bin/set-authkey.sh << 'EOF'
#!/bin/sh
# ============================================
# Cập nhật Tailscale Auth Key
# ============================================

echo "=== CẬP NHẬT TAILSCALE AUTH KEY ==="
echo ""
echo "Lấy auth key tại: https://login.tailscale.com/admin/settings/keys"
echo ""
echo "Nhập auth key mới:"
read -r NEW_AUTHKEY

if [ -z "$NEW_AUTHKEY" ]; then
    echo "❌ Không có auth key, bỏ qua"
    exit 1
fi

# Cập nhật config
if [ -f /opt/etc/tailscale.conf ]; then
    sed -i "s/export TS_AUTHKEY=.*/export TS_AUTHKEY=\"$NEW_AUTHKEY\"/" /opt/etc/tailscale.conf
else
    echo "export TS_AUTHKEY=\"$NEW_AUTHKEY\"" > /opt/etc/tailscale.conf
fi

echo "   ✅ Đã cập nhật auth key"

# Restart Tailscale
echo "   Restart Tailscale để áp dụng..."
/opt/etc/init.d/S99tailscale restart

echo "✅ Hoàn tất"
EOF

chmod +x /opt/bin/set-authkey.sh
check_success

# 17. Tạo symbolic links
echo ""
echo "🔗 17. Tạo symbolic links..."
ln -sf /opt/etc/init.d/S95ntp /opt/etc/init.d/rc.d/S95ntp 2>/dev/null
ln -sf /opt/etc/init.d/S97adguardhome /opt/etc/init.d/rc.d/S97adguardhome 2>/dev/null
ln -sf /opt/etc/init.d/S98tailscaled /opt/etc/init.d/rc.d/S98tailscaled 2>/dev/null
ln -sf /opt/etc/init.d/S99tailscale /opt/etc/init.d/rc.d/S99tailscale 2>/dev/null
check_success

# 18. Cấu hình CRON
echo ""
echo "⏰ 18. Cấu hình CRON..."

# Backup cron cũ
if [ -f /opt/etc/crontab ]; then
    cp /opt/etc/crontab /opt/etc/crontab.backup
fi

# Tạo file cron
cat > /opt/etc/crontab << 'EOF'
# Crontab cho Keenetic
# Phut Gio Ngay Thang Thuong  Command
# ============================================

# Restart Tailscale + AdGuard Home moi ngay luc 5h sang
0 5 * * * /opt/bin/restart-services.sh

# Kiem tra dich vu moi 30 phut
*/30 * * * * /opt/bin/check-and-restart.sh

# Fix DNS conflict moi gio
0 * * * * /opt/bin/fix-dns-conflict.sh

# Kiem tra va fix DNS sau reboot
@reboot /opt/bin/setup-dns.sh

# Đồng bộ thời gian mỗi 6 tiếng
0 */6 * * * /opt/bin/sync-time.sh
EOF

# Tạo symlink
ln -sf /opt/etc/crontab /etc/crontab 2>/dev/null

# Khởi động CRON
if ! pgrep crond >/dev/null; then
    echo "   Khoi dong CRON daemon..."
    crond -c /opt/etc/crontabs -L /opt/var/log/cron.log
    echo "   ✅ CRON da khoi dong"
else
    echo "   CRON da chay, reload config..."
    pkill crond
    sleep 1
    crond -c /opt/etc/crontabs -L /opt/var/log/cron.log
    echo "   ✅ CRON da reload"
fi
check_success

# 19. Chạy setup DNS lần đầu
echo ""
echo "🔧 19. Cấu hình DNS lần đầu..."
/opt/bin/setup-dns.sh

# 20. Tạo script uninstall
echo ""
echo "🗑️ 20. Tạo script uninstall..."
cat > /opt/bin/uninstall.sh << 'EOF'
#!/bin/sh
# ============================================
# Gỡ cài đặt Tailscale & AdGuard Home
# ============================================

echo "=== BAT DAU GO CAI DAT ==="
echo ""
echo "⚠️ Ban co chac chan muon go cai dat?"
echo "Nhap 'yes' de tiep tuc: "
read confirm

if [ "$confirm" != "yes" ]; then
    echo "Huy bo go cai dat."
    exit 0
fi

echo "1. Dung dich vu..."
/opt/etc/init.d/S99tailscale stop 2>/dev/null
/opt/etc/init.d/S98tailscaled stop 2>/dev/null
/opt/etc/init.d/S97adguardhome stop 2>/dev/null
/opt/etc/init.d/S95ntp stop 2>/dev/null

echo "2. Xoa init scripts..."
rm -f /opt/etc/init.d/S95ntp
rm -f /opt/etc/init.d/S97adguardhome
rm -f /opt/etc/init.d/S98tailscaled
rm -f /opt/etc/init.d/S99tailscale
rm -f /opt/etc/init.d/rc.d/S95ntp
rm -f /opt/etc/init.d/rc.d/S97adguardhome
rm -f /opt/etc/init.d/rc.d/S98tailscaled
rm -f /opt/etc/init.d/rc.d/S99tailscale

echo "3. Xoa netfilter rules..."
rm -f /opt/etc/ndm/netfilter.d/100-tailscale.sh

echo "4. Xoa configuration..."
rm -rf /opt/etc/AdGuardHome
rm -rf /opt/var/lib/tailscale
rm -f /opt/etc/tailscale.conf
rm -f /opt/etc/crontab
rm -f /opt/etc/ntp.conf
rm -f /opt/etc/timezone

echo "5. Xoa utility scripts..."
rm -f /opt/bin/start-all.sh
rm -f /opt/bin/check-all.sh
rm -f /opt/bin/restart-services.sh
rm -f /opt/bin/check-and-restart.sh
rm -f /opt/bin/fix-dns-conflict.sh
rm -f /opt/bin/setup-dns.sh
rm -f /opt/bin/setup-timezone.sh
rm -f /opt/bin/sync-time.sh
rm -f /opt/bin/set-authkey.sh

echo "6. Restore DNS config..."
if command -v ndmc >/dev/null 2>&1; then
    ndmc -c "dns server enable" 2>/dev/null
    ndmc -c "dns forward off" 2>/dev/null
fi

echo "7. Xoa packages (optional)..."
echo "   De xoa package: opkg remove tailscale adguardhome-go ntpclient"

echo ""
echo "✅ Go cai dat hoan tat!"
EOF

chmod +x /opt/bin/uninstall.sh
check_success

# ============================================
# HOÀN TẤT CÀI ĐẶT
# ============================================
echo ""
echo "========================================"
echo "   🎉 CAI DAT HOAN TAT! 🎉"
echo "========================================"
echo ""
echo "📡 THONG TIN MANG:"
echo "  IP Router: $DETECTED_IP"
echo "  Subnet: $DETECTED_SUBNET"
echo ""
echo "📌 THU TU KHOI DONG (QUAN TRONG):"
echo "  1. NTP (S95)        - Đồng bộ thời gian"
echo "  2. AdGuard Home (S97) - DNS server"
echo "  3. tailscaled (S98)   - Tailscale daemon"
echo "  4. Tailscale (S99)    - Tailscale client + Exit Node"
echo ""
echo "🔑 ĐỂ NHẬP AUTH KEY:"
echo "   /opt/bin/set-authkey.sh"
echo ""
echo "🚀 De khoi dong tat ca:"
echo "   /opt/bin/start-all.sh"
echo ""
echo "🔍 De kiem tra:"
echo "   /opt/bin/check-all.sh"
echo ""
echo "🔧 De fix DNS conflict:"
echo "   /opt/bin/fix-dns-conflict.sh"
echo ""
echo "🕐 De dong bo thoi gian:"
echo "   /opt/bin/sync-time.sh"
echo ""
echo "📋 De kiem tra CRON:"
echo "   /opt/bin/check-cron.sh"
echo ""
echo "🗑️ De go cai dat:"
echo "   /opt/bin/uninstall.sh"
echo ""
echo "⚠️ IMPORTANT - CAU HINH ADGUARD HOME:"
echo "   Truy cap http://${DETECTED_IP}:3000"
echo "   De thiet lap AdGuard Home lan dau"
echo ""
echo "📋 CRON SCHEDULE:"
echo "  • 5:00 AM hang ngay  - Restart tat ca dich vu"
echo "  • Moi 30 phut        - Kiem tra va restart neu chet"
echo "  • Moi gio             - Fix DNS conflict"
echo "  • Moi 6 tieng        - Dong bo thoi gian"
echo "  • @reboot             - Setup DNS sau reboot"
echo ""
echo "📁 LOG FILES:"
echo "  /opt/var/log/restart-services.log  - Restart log"
echo "  /opt/var/log/auto-restart.log      - Auto-restart log"
echo "  /opt/var/log/cron.log              - Cron log"
echo "  /opt/var/log/dns-setup.log         - DNS setup log"
echo "  /opt/var/log/ntp.log               - NTP log"
echo "  /opt/var/log/time-sync.log         - Time sync log"
echo ""
echo "🔑 CAC VI TRI CAN THAY DOI:"
echo "========================================"
echo "1. AUTH KEY trong /opt/etc/tailscale.conf"
echo "   export TS_AUTHKEY=\"tskey-auth-YOUR_KEY_HERE\""
echo ""
echo "2. SUBNET đã tự động phát hiện: $DETECTED_SUBNET"
echo "   (Có thể thay đổi trong /opt/etc/tailscale.conf nếu cần)"
echo "========================================"
echo ""
echo "✅ Script da san sang!"
