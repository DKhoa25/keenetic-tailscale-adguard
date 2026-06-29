#!/bin/sh
# ============================================
# BACKUP MODULE
# ============================================

BACKUP_DIR=""

backup_old_installation() {
    if [ -d "$INSTALL_DIR" ]; then
        log_info "Phát hiện cài đặt cũ tại $INSTALL_DIR"
        
        BACKUP_DIR="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        log_info "Đang backup vào: $BACKUP_DIR"
        
        if cp -r "$INSTALL_DIR" "$BACKUP_DIR" 2>/dev/null; then
            log_success "Backup thành công"
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
