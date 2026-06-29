#!/bin/sh
# ============================================
# LOGGER MODULE
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

show_banner() {
    echo ""
    echo "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo "${CYAN}║  TAILSCALE + ADGUARD HOME INSTALLER       ║${NC}"
    echo "${CYAN}║  Version: 2.0 - Modular                   ║${NC}"
    echo "${CYAN}║  Cho Keenetic Router                     ║${NC}"
    echo "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""
}

show_completion() {
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
}
