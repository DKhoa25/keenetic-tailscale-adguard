#!/bin/sh
# ============================================
# ADGUARD HOME INSTALLATION SCRIPT
# ============================================

install_adguard() {
    echo "📦 Đang cài đặt AdGuard Home..."
    
    # Kiểm tra nếu đã cài
    if /etc/init.d/adguardhome status >/dev/null 2>&1; then
        echo "✅ AdGuard Home đã được cài đặt"
        return 0
    fi
    
    # Cài đặt AdGuard từ opkg
    opkg update
    opkg install adguardhome
    
    if [ $? -eq 0 ]; then
        echo "✅ Cài đặt AdGuard Home thành công"
        return 0
    else
        echo "❌ Cài đặt AdGuard Home thất bại"
        return 1
    fi
}

# Chạy nếu script được gọi trực tiếp
if [ "$0" = "$1" ]; then
    install_adguard
fi
