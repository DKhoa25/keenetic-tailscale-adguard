#!/bin/sh
# ============================================
# ENVIRONMENT CHECK MODULE
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
    
    DNS_SERVERS="8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9"
    
    for dns in $DNS_SERVERS; do
        if ping -c 1 -W 2 "$dns" >/dev/null 2>&1; then
            log_success "Có kết nối internet (ping $dns thành công)"
            return 0
        fi
    done
    
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
    
    if ! opkg --version >/dev/null 2>&1; then
        log_error "opkg không hoạt động đúng!"
        exit 1
    fi
    
    log_success "opkg sẵn sàng"
}

install_dependencies() {
    log_step "CÀI ĐẶT DEPENDENCIES"
    
    local missing_deps=""
    
    for pkg in ca-certificates wget curl; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            missing_deps="$missing_deps $pkg"
        fi
    done
    
    if [ -z "$missing_deps" ]; then
        log_success "Tất cả dependencies đã được cài đặt"
        return 0
    fi
    
    log_info "Các gói cần cài thêm: $missing_deps"
    
    log_info "Cập nhật danh sách gói..."
    if ! opkg update 2>&1 | tee -a "$LOG_FILE" | grep -v "Downloading"; then
        log_error "Không thể cập nhật danh sách gói!"
        return 1
    fi
    
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
