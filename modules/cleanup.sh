#!/bin/sh
# ============================================
# CLEANUP & ERROR HANDLER MODULE
# ============================================

cleanup() {
    log_info "Dọn dẹp..."
    find /tmp -name "keenetic-*" -type f -mtime +1 -delete 2>/dev/null || true
    log_success "Dọn dẹp hoàn tất"
}

error_handler() {
    local exit_code=$?
    log_error "Script gặp lỗi tại dòng $1"
    log_error "Mã lỗi: $exit_code"
    
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
