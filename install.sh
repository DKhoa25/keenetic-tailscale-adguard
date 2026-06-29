#!/bin/sh
# ============================================
# Cài đặt Tailscale + AdGuard Home + NTP trên Keenetic
# Version: 1
# ============================================

echo "=== BAT DAU CAI DAT TAILSCALE & ADGUARD HOME & NTP ==="
echo ""

# Kiểm tra quyền root
if [ "$(id -u)" != "0" ]; then
    echo "❌ LỖI: Script phải chạy với quyền root!"
    exit 1
fi

# ============================================
# PHẦN 1: CÀI ĐẶT GIT VÀ CLONE REPOSITORY
# ============================================

echo "📦 0. Cài đặt Git và clone repository..."
echo ""

# Kiểm tra và cài đặt Git
install_git() {
    echo "   🔍 Kiểm tra Git..."
    
    if command -v git >/dev/null 2>&1; then
        echo "   ✅ Git đã được cài đặt: $(git --version)"
        return 0
    fi
    
    echo "   ⚠️ Git chưa được cài đặt. Đang cài đặt..."
    
    # Cập nhật package list
    echo "   📥 Đang cập nhật opkg..."
    opkg update
    
    # Cài đặt Git và các dependencies
    echo "   📥 Đang cài đặt git, git-http, ca-certificates..."
    opkg install git git-http ca-certificates
    
    if [ $? -eq 0 ] && command -v git >/dev/null 2>&1; then
        echo "   ✅ Git đã được cài đặt thành công: $(git --version)"
        return 0
    else
        echo "   ❌ Không thể cài đặt Git!"
        echo "   💡 Thử tải trực tiếp script install.sh..."
        return 1
    fi
}

# Hàm clone repository
clone_repo() {
    local REPO_URL="https://github.com/DKhoa25/keenetic-tailscale-adguard.git"
    local INSTALL_DIR="/opt/keenetic-tailscale-adguard"
    
    echo ""
    echo "   📥 Đang clone repository..."
    
    # Xóa thư mục cũ nếu tồn tại
    if [ -d "$INSTALL_DIR" ]; then
        echo "   ⚠️ Thư mục cũ tồn tại, đang xóa..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone repository
    git clone "$REPO_URL" "$INSTALL_DIR"
    
    if [ $? -eq 0 ] && [ -d "$INSTALL_DIR" ]; then
        echo "   ✅ Clone thành công vào: $INSTALL_DIR"
        cd "$INSTALL_DIR"
        
        # Kiểm tra file install.sh
        if [ -f "$INSTALL_DIR/install.sh" ]; then
            echo "   ✅ Tìm thấy install.sh"
            chmod +x "$INSTALL_DIR/install.sh"
            return 0
        else
            echo "   ❌ Không tìm thấy install.sh trong repository!"
            return 1
        fi
    else
        echo "   ❌ Clone thất bại!"
        return 1
    fi
}

# Hàm tải trực tiếp install.sh (fallback)
download_install_script() {
    echo ""
    echo "   📥 Đang tải trực tiếp install.sh..."
    
    local INSTALL_DIR="/opt/keenetic-tailscale-adguard"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Thử wget
    if command -v wget >/dev/null 2>&1; then
        wget -O install.sh https://raw.githubusercontent.com/DKhoa25/keenetic-tailscale-adguard/main/install.sh
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o install.sh https://raw.githubusercontent.com/DKhoa25/keenetic-tailscale-adguard/main/install.sh
    else
        echo "   ❌ Không có wget hoặc curl!"
        return 1
    fi
    
    if [ $? -eq 0 ] && [ -f "install.sh" ]; then
        echo "   ✅ Tải install.sh thành công!"
        chmod +x install.sh
        return 0
    else
        echo "   ❌ Tải install.sh thất bại!"
        return 1
    fi
}

# ============================================
# PHẦN 2: CHẠY SCRIPT CÀI ĐẶT CHÍNH
# ============================================

# Thử cài Git và clone
if install_git; then
    if clone_repo; then
        echo ""
        echo "✅ Đã chuẩn bị xong repository!"
        echo "🚀 Bắt đầu cài đặt chính..."
        echo ""
        
        # Chạy script install.sh trong repository
        cd /opt/keenetic-tailscale-adguard
        exec ./install.sh
        exit 0
    else
        echo ""
        echo "⚠️ Clone thất bại, thử tải trực tiếp install.sh..."
        if download_install_script; then
            echo ""
            echo "✅ Tải thành công install.sh!"
            echo "🚀 Bắt đầu cài đặt chính..."
            echo ""
            cd /opt/keenetic-tailscale-adguard
            exec ./install.sh
            exit 0
        fi
    fi
else
    echo ""
    echo "⚠️ Không thể cài Git, thử tải trực tiếp install.sh..."
    if download_install_script; then
        echo ""
        echo "✅ Tải thành công install.sh!"
        echo "🚀 Bắt đầu cài đặt chính..."
        echo ""
        cd /opt/keenetic-tailscale-adguard
        exec ./install.sh
        exit 0
    fi
fi

# ============================================
# PHẦN 3: FALLBACK - TẠO SCRIPT TỪ TRONG SCRIPT
# ============================================

echo ""
echo "⚠️ Không thể tải script cài đặt chính!"
echo "Đang tạo script cài đặt từ source code..."

# [Phần còn lại của script install.sh sẽ được đặt ở đây]
# (Paste toàn bộ nội dung install.sh gốc vào đây)

echo ""
echo "❌ Không thể tiếp tục!"
echo "Vui lòng kiểm tra kết nối internet và thử lại."
exit 1
