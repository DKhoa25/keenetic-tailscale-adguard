#!/bin/sh
# ============================================
# CONFIGURATION MODULE
# ============================================

# URL cơ sở để tải file
RAW_URL="https://raw.githubusercontent.com/DKhoa25/keenetic-tailscale-adguard/main"
INSTALL_DIR="/opt/keenetic-tailscale-adguard"
LOG_DIR="/var/log/keenetic-install"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"

# Cấu hình thời gian và dung lượng
MIN_REQUIRED_SPACE=51200  # 50MB tính bằng KB
TIMEOUT=60
MAX_RETRIES=3
RETRY_DELAY=5

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Export biến
export RAW_URL INSTALL_DIR LOG_DIR LOG_FILE
export MIN_REQUIRED_SPACE TIMEOUT MAX_RETRIES RETRY_DELAY
export RED GREEN YELLOW BLUE CYAN NC
