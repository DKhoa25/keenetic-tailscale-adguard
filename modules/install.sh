#!/bin/sh
# ============================================
# MAIN INSTALLER MODULE
# ============================================

run_main_installer() {
    log_step "BẮT ĐẦU CÀI ĐẶT CHÍNH"
    
    cd "$INSTALL_DIR" || {
        log_error "Không thể truy cập $INSTALL_DIR"
        return 1
    }
    
    log_info "Thư mục cài đặt: $INSTALL_DIR"
    log_info "Script chính: install.sh"
    
    if [ ! -f "install.sh" ]; then
        log_error "Không tìm thấy install.sh!"
        return 1
    fi
    
    if [ ! -x "install.sh" ]; then
        log_info "Cấp quyền thực thi..."
        chmod +x install.sh
    fi
    
    export INSTALL_DIR="$INSTALL_DIR"
    export LOG_FILE="$LOG_FILE"
    
    log_info "Bắt đầu cài đặt..."
    echo ""
    
    local attempt=0
    local max_attempts=2
    local install_success=false
    
    while [ $attempt -lt $max_attempts ] && [ "$install_success" = false ]; do
        attempt=$((attempt + 1))
        log_info "Lần chạy cài đặt thứ $attempt/$max_attempts"
        
        if ./install.sh 2>&1 | tee -a "$LOG_FILE"; then
            install_success=true
            log_success "Script install.sh chạy thành công!"
            break
        else
            local exit_code=$?
            log_error "Script cài đặt chính thất bại với mã lỗi: $exit_code"
            
            if [ $attempt -lt $max_attempts ]; then
                log_warning "Sẽ thử lại sau 5 giây..."
                sleep 5
            else
                log_error "Đã thử $max_attempts lần nhưng thất bại!"
                return $exit_code
            fi
        fi
    done
    
    return 0
}

post_install_check() {
    log_step "KIỂM TRA SAU CÀI ĐẶT"
    
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
