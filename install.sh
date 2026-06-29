#!/bin/sh
# ============================================
# KEENETIC TAILSCALE + ADGUARD COMPLETE INSTALLER
# Version: 1
# ============================================

set -e  # Dừng script nếu có lỗi

# ============================================
# CẤU HÌNH
# ============================================
REPO_URL="https://github.com/DKhoa25/keenetic-tailscale-adguard.git"
INSTALL_DIR="/opt/keenetic-tailscale-adguard"
LOG_DIR="/var/log/keenetic-install"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"
MIN_REQUIRED_SPACE=51200  # 50MB tính bằng KB
TIMEOUT=60  # Timeout cho các thao tác mạng
GIT_BRANCH="main"  # Nhánh chính của repo

# ============================================
# MÀU SẮC CHO OUTPUT
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# HÀM LOGGING
# ============================================
setup_logging() {
    mkdir -p "$LOG_DIR"
    exec 2>&1 | tee -a "$LOG_FILE"
    echo "📝 Log được lưu tại: $LOG_FILE"
}

log_info() {
    echo "${BLUE}ℹ️${NC} $1"
}

log_success() {
    echo "${GREEN}✅${NC} $1"
}

log_warning() {
    echo "${YELLOW}⚠️${NC} $1"
}

log_error() {
    echo "${RED}❌${NC} $1"
}

log_step() {
    echo ""
    echo "${CYAN}========================================${NC}"
    echo "${CYAN}  $1${NC}"
    echo "${CYAN}========================================${NC}"
    echo ""
}

# ============================================
# KIỂM TRA MÔI TRƯỜNG
# ============================================
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_error "Script phải chạy với quyền root!"
        exit 1
    fi
}

check_architecture() {
    arch=$(uname -m)
    log_info "Kiến trúc hệ thống: $arch"
    
    case "$arch" in
        aarch64|arm64|armv7l|mips|mips64|i386|x86_64)
            log_success "Hỗ trợ kiến trúc $arch"
            ;;
        *)
            log_warning "Kiến trúc $arch có thể không được hỗ trợ đầy đủ"
            read -p "Tiếp tục? (y/N): " confirm
            if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
                exit 1
            fi
            ;;
    esac
}

check_space() {
    log_info "Kiểm tra dung lượng đĩa..."
    
    # Lấy dung lượng trống của partition chứa /opt
    if [ -d "/opt" ]; then
        available=$(df /opt | awk 'NR==2 {print $4}')
    else
        available=$(df / | awk 'NR==2 {print $4}')
    fi
    
    if [ -z "$available" ]; then
        log_warning "Không thể xác định dung lượng trống"
        return 0
    fi
    
    if [ "$available" -lt "$MIN_REQUIRED_SPACE" ]; then
        log_error "Không đủ dung lượng trống!"
        log_info "Cần: $((MIN_REQUIRED_SPACE / 1024)) MB"
        log_info "Có: $((available / 1024)) MB"
        log_info "Vui lòng giải phóng dung lượng và thử lại."
        exit 1
    fi
    
    log_success "Đủ dung lượng: $((available / 1024)) MB trống"
}

check_internet() {
    log_step "KIỂM TRA KẾT NỐI MẠNG"
    
    log_info "Kiểm tra kết nối internet..."
    
    # Danh sách các DNS để ping
    DNS_SERVERS="8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9"
    
    for dns in $DNS_SERVERS; do
        if ping -c 1 -W 2 "$dns" >/dev/null 2>&1; then
            log_success "Có kết nối internet (ping $dns thành công)"
            return 0
        fi
    done
    
    # Thử curl/wget
    if command -v curl >/dev/null 2>&1; then
        if curl -s --connect-timeout 5 https://google.com >/dev/null 2>&1; then
            log_success "Có kết nối internet (curl thành công)"
            return 0
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q --timeout=5 -O- https://google.com >/dev/null 2>&1; then
            log_success "Có kết nối internet (wget thành công)"
            return 0
        fi
    fi
    
    log_error "Không có kết nối internet!"
    log_error "Vui lòng kiểm tra kết nối mạng và DNS."
    return 1
}

check_opkg() {
    log_info "Kiểm tra trình quản lý gói opkg..."
    
    if ! command -v opkg >/dev/null 2>&1; then
        log_error "Không tìm thấy opkg!"
        log_error "Script này chỉ hỗ trợ các thiết bị chạy OpenWrt/Keenetic."
        exit 1
    fi
    
    # Kiểm tra opkg hoạt động
    if ! opkg --version >/dev/null 2>&1; then
        log_error "opkg không hoạt động đúng!"
        exit 1
    fi
    
    log_success "opkg sẵn sàng"
}

# ============================================
# BACKUP & RESTORE
# ============================================
backup_old_installation() {
    if [ -d "$INSTALL_DIR" ]; then
        log_info "Phát hiện cài đặt cũ tại $INSTALL_DIR"
        
        BACKUP_DIR="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        log_info "Đang backup vào: $BACKUP_DIR"
        
        if cp -r "$INSTALL_DIR" "$BACKUP_DIR" 2>/dev/null; then
            log_success "Backup thành công"
            
            # Xóa thư mục cũ sau khi backup
            rm -rf "$INSTALL_DIR"
            log_info "Đã xóa thư mục cũ"
        else
            log_warning "Backup thất bại, tiếp tục cài đặt mới"
        fi
    fi
}

restore_from_backup() {
    if [ $1 -ne 0 ] && [ -d "$BACKUP_DIR" ]; then
        log_warning "Cài đặt thất bại, khôi phục từ backup..."
        if cp -r "$BACKUP_DIR" "$INSTALL_DIR" 2>/dev/null; then
            log_success "Khôi phục thành công"
        else
            log_error "Không thể khôi phục từ backup"
        fi
    fi
}

# ============================================
# CÀI ĐẶT DEPENDENCIES
# ============================================
install_dependencies() {
    log_step "CÀI ĐẶT DEPENDENCIES"
    
    local deps=""
    local missing_deps=""
    
    # Kiểm tra các gói cần thiết
    for pkg in git ca-certificates wget curl; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            missing_deps="$missing_deps $pkg"
        fi
    done
    
    if [ -z "$missing_deps" ]; then
        log_success "Tất cả dependencies đã được cài đặt"
        return 0
    fi
    
    log_info "Các gói cần cài thêm: $missing_deps"
    
    # Cập nhật package list
    log_info "Cập nhật danh sách gói..."
    if ! opkg update 2>&1 | tee -a "$LOG_FILE" | grep -v "Downloading"; then
        log_error "Không thể cập nhật danh sách gói!"
        return 1
    fi
    
    # Cài đặt từng gói
    for pkg in $missing_deps; do
        log_info "Đang cài đặt: $pkg..."
        if opkg install "$pkg" 2>&1 | tee -a "$LOG_FILE" | grep -v "Package"; then
            log_success "Đã cài $pkg"
        else
            log_warning "Không thể cài $pkg, tiếp tục..."
        fi
    done
    
    return 0
}

# ============================================
# CLONE HOẶC DOWNLOAD
# ============================================
clone_repository() {
    log_step "TẢI MÃ NGUỒN"
    
    log_info "Clone từ GitHub..."
    
    # Thử clone với các tùy chọn tối ưu
    if git clone --depth 1 --branch "$GIT_BRANCH" --single-branch \
        --config http.timeout=$TIMEOUT \
        --config core.compression=0 \
        "$REPO_URL" "$INSTALL_DIR" 2>&1 | tee -a "$LOG_FILE" | grep -v "Cloning into"; then
        
        if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/install.sh" ]; then
            log_success "Clone thành công"
            chmod +x "$INSTALL_DIR/install.sh"
            chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
            
            # Kiểm tra checksum
            verify_checksum "$INSTALL_DIR/install.sh"
            return 0
        fi
    fi
    
    log_warning "Clone thất bại, thử phương án khác..."
    return 1
}

download_direct() {
    log_info "Tải trực tiếp từ GitHub (phương án dự phòng)..."
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || return 1
    
    local RAW_URL="https://raw.githubusercontent.com/DKhoa25/keenetic-tailscale-adguard/$GIT_BRANCH/install.sh"
    
    # Thử nhiều phương pháp tải
    if command -v wget >/dev/null 2>&1; then
        wget -q --timeout=$TIMEOUT --show-progress -O install.sh "$RAW_URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -L --connect-timeout $TIMEOUT -o install.sh "$RAW_URL"
    else
        log_error "Không có wget hoặc curl!"
        return 1
    fi
    
    if [ $? -eq 0 ] && [ -f "install.sh" ] && [ -s "install.sh" ]; then
        log_success "Tải thành công"
        chmod +x install.sh
        verify_checksum "install.sh"
        return 0
    fi
    
    log_error "Tải thất bại"
    return 1
}

verify_checksum() {
    local file="$1"
    
    # Tạo checksum cơ bản (không bắt buộc)
    if command -v sha256sum >/dev/null 2>&1; then
        local checksum=$(sha256sum "$file" | awk '{print $1}')
        log_info "SHA256 checksum: $checksum"
    fi
}

# ============================================
# CÀI ĐẶT CHÍNH
# ============================================
run_installer() {
    log_step "BẮT ĐẦU CÀI ĐẶT CHÍNH"
    
    cd "$INSTALL_DIR" || {
        log_error "Không thể truy cập $INSTALL_DIR"
        return 1
    }
    
    log_info "Thư mục cài đặt: $INSTALL_DIR"
    log_info "Script chính: install.sh"
    
    # Kiểm tra file tồn tại và có thể đọc được
    if [ ! -f "install.sh" ]; then
        log_error "Không tìm thấy install.sh!"
        return 1
    fi
    
    if [ ! -x "install.sh" ]; then
        log_info "Cấp quyền thực thi..."
        chmod +x install.sh
    fi
    
    # Lưu biến môi trường
    export INSTALL_DIR="$INSTALL_DIR"
    export LOG_FILE="$LOG_FILE"
    
    log_info "Bắt đầu cài đặt..."
    echo ""
    
    # Chạy script với xử lý lỗi
    if ./install.sh 2>&1 | tee -a "$LOG_FILE"; then
        return 0
    else
        local exit_code=$?
        log_error "Script cài đặt chính thất bại với mã lỗi: $exit_code"
        return $exit_code
    fi
}

# ============================================
# KIỂM TRA SAU CÀI ĐẶT
# ============================================
post_install_check() {
    log_step "KIỂM TRA SAU CÀI ĐẶT"
    
    # Kiểm tra dịch vụ
    local services="tailscale adguardhome"
    local all_ok=true
    
    for svc in $services; do
        if /etc/init.d/"$svc" status >/dev/null 2>&1; then
            log_success "$svc đang chạy"
        else
            log_warning "$svc không chạy hoặc chưa được cài đặt"
            all_ok=false
        fi
    done
    
    # Hiển thị thông tin
    echo ""
    log_info "=== THÔNG TIN CÀI ĐẶT ==="
    echo "📍 Thư mục: $INSTALL_DIR"
    echo "📝 Log: $LOG_FILE"
    
    if [ -f "/etc/config/tailscale" ]; then
        echo "🔗 Tailscale: /etc/config/tailscale"
    fi
    
    if [ -f "/etc/config/adguardhome" ]; then
        echo "🛡️ AdGuard: /etc/config/adguardhome"
    fi
    
    echo ""
}

# ============================================
# XỬ LÝ LỖI & DỌN DẸP
# ============================================
cleanup() {
    log_info "Dọn dẹp..."
    
    # Xóa các file tạm thời
    find /tmp -name "keenetic-*" -type f -mtime +1 -delete 2>/dev/null || true
    
    log_success "Dọn dẹp hoàn tất"
}

error_handler() {
    local exit_code=$?
    log_error "Script gặp lỗi tại dòng $1"
    log_error "Mã lỗi: $exit_code"
    
    # Hiển thị thông tin debugging
    echo ""
    log_info "=== THÔNG TIN GỠ LỖI ==="
    echo "OS: $(uname -a)"
    echo "Kernel: $(uname -r)"
    echo "Arch: $(uname -m)"
    echo "Memory: $(free -m | grep Mem | awk '{print $2}') MB"
    
    if [ -f "$LOG_FILE" ]; then
        echo "Log: $LOG_FILE"
        echo "10 dòng cuối log:"
        tail -n 10 "$LOG_FILE"
    fi
    
    exit $exit_code
}

# ============================================
# MAIN - BẮT ĐẦU
# ============================================

# Thiết lập trap để bắt lỗi
trap 'error_handler $LINENO' ERR
trap cleanup EXIT

# Khởi tạo logging
setup_logging

# Hiển thị banner
echo ""
echo "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo "${CYAN}║  TAILSCALE + ADGUARD HOME INSTALLER       ║${NC}"
echo "${CYAN}║  Version: 5.0 - Hoàn thiện               ║${NC}"
echo "${CYAN}║  Cho Keenetic Router                     ║${NC}"
echo "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""

# Kiểm tra môi trường
log_step "KIỂM TRA MÔI TRƯỜNG"
check_root
check_architecture
check_space
check_opkg

# Kiểm tra kết nối mạng
if ! check_internet; then
    log_error "Không có kết nối internet!"
    exit 1
fi

# Backup cài đặt cũ
backup_old_installation

# Cài đặt dependencies
if ! install_dependencies; then
    log_error "Không thể cài đặt dependencies!"
    exit 1
fi

# Tải mã nguồn
if ! clone_repository; then
    log_warning "Clone thất bại, thử tải trực tiếp..."
    if ! download_direct; then
        log_error "Không thể tải mã nguồn!"
        log_error "Vui lòng kiểm tra kết nối và thử lại."
        restore_from_backup $?
        exit 1
    fi
fi

# Chạy cài đặt
if ! run_installer; then
    log_error "Cài đặt thất bại!"
    restore_from_backup $?
    exit 1
fi

# Kiểm tra sau cài đặt
post_install_check

# Hoàn tất
log_step "CÀI ĐẶT HOÀN TẤT"

echo "${GREEN}✅ Cài đặt Tailscale và AdGuard Home thành công!${NC}"
echo ""
echo "${BLUE}📌 Hướng dẫn tiếp theo:${NC}"
echo "   • Kiểm tra Tailscale: tailscale status"
echo "   • Kiểm tra AdGuard: /etc/init.d/adguardhome status"
echo "   • Xem log: cat $LOG_FILE"
echo ""
echo "${YELLOW}⚠️ Lưu ý:${NC}"
echo "   • Khởi động lại router nếu gặp vấn đề"
echo "   • Truy cập AdGuard tại: http://$(uci get network.lan.ipaddr 2>/dev/null || echo '192.168.1.1'):3000"
echo "   • Đăng nhập Tailscale: tailscale up"
echo ""

# Thoát thành công
exit 0
