#!/bin/sh
# ============================================
# KEENETIC TAILSCALE + ADGUARD COMPLETE INSTALLER
# Main Entry Point
# Version: 2.0 - Modular
# ============================================

set -e

# Lấy đường dẫn thư mục script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Load modules
for module in config logger check backup download install cleanup; do
    if [ -f "$MODULES_DIR/$module.sh" ]; then
        . "$MODULES_DIR/$module.sh"
    else
        echo "❌ Không tìm thấy module: $module.sh"
        exit 1
    fi
done

# Thiết lập trap để bắt lỗi
trap 'error_handler $LINENO' ERR
trap 'cleanup' EXIT

# Khởi tạo logging
setup_logging

# Hiển thị banner
show_banner

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
if ! download_files; then
    log_error "Không thể tải mã nguồn!"
    log_error "Vui lòng kiểm tra kết nối và thử lại."
    exit 1
fi

# Chạy cài đặt
if ! run_main_installer; then
    log_error "Cài đặt thất bại!"
    exit 1
fi

# Kiểm tra sau cài đặt
post_install_check

# Hoàn tất
show_completion

exit 0
