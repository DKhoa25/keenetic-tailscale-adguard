#!/bin/sh
# ============================================
# UNINSTALL SCRIPT
# ============================================

uninstall_all() {
    echo "🗑️ Đang gỡ cài đặt Tailscale và AdGuard Home..."
    
    # Dừng và gỡ Tailscale
    if /etc/init.d/tailscale status >/dev/null 2>&1; then
        echo "Dừng Tailscale..."
        /etc/init.d/tailscale stop
        /etc/init.d/tailscale disable
    fi
    
    # Dừng và gỡ AdGuard
    if /etc/init.d/adguardhome status >/dev/null 2>&1; then
        echo "Dừng AdGuard Home..."
        /etc/init.d/adguardhome stop
        /etc/init.d/adguardhome disable
    fi
    
    # Xóa gói
    echo "Gỡ cài đặt gói..."
    opkg remove tailscale adguardhome 2>/dev/null
    
    # Xóa thư mục cài đặt
    if [ -d "/opt/keenetic-tailscale-adguard" ]; then
        echo "Xóa thư mục cài đặt..."
        rm -rf /opt/keenetic-tailscale-adguard
    fi
    
    echo "✅ Gỡ cài đặt hoàn tất!"
}

# Chạy script
uninstall_all
