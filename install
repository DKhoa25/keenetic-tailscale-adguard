#!/bin/sh
# ============================================
# KEENETIC TAILSCALE + ADGUARD COMPLETE INSTALLER
# Version: 1
# ============================================

set -e  # Dung script neu co loi

# ============================================
# CAU HINH
# ============================================
RAW_URL="https://raw.githubusercontent.com/DKhoa25/keenetic-tailscale-adguard/main"
INSTALL_DIR="/opt/keenetic-tailscale-adguard"
LOG_DIR="/var/log/keenetic-install"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"
MIN_REQUIRED_SPACE=51200  # 50MB tinh bang KB
TIMEOUT=60  # Timeout cho cac thao tac mang
MAX_RETRIES=3  # So lan thu lai toi da
RETRY_DELAY=5  # Giay cho giua cac lan thu

# ============================================
# MAU SAC CHO OUTPUT
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# HAM LOGGING
# ============================================
setup_logging() {
    mkdir -p "$LOG_DIR"
    exec 2>&1 | tee -a "$LOG_FILE"
    echo " Log duoc luu tai: $LOG_FILE"
}

log_info() {
    echo "${BLUE}i${NC} $1"
}

log_success() {
    echo "${GREEN}√${NC} $1"
}

log_warning() {
    echo "${YELLOW}!${NC} $1"
}

log_error() {
    echo "${RED}x${NC} $1"
}

log_step() {
    echo ""
    echo "${CYAN}========================================${NC}"
    echo "${CYAN}  $1${NC}"
    echo "${CYAN}========================================${NC}"
    echo ""
}

# ============================================
# KIEM TRA MOI TRUONG
# ============================================
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_error "Script phai chay voi quyen root!"
        exit 1
    fi
}

check_architecture() {
    arch=$(uname -m)
    log_info "Kien truc he thong: $arch"
    
    case "$arch" in
        aarch64|arm64|armv7l|mips|mips64|i386|x86_64)
            log_success "Ho tro kien truc $arch"
            ;;
        *)
            log_warning "Kien truc $arch co the khong duoc ho tro day du"
            read -p "Tiep tuc? (y/N): " confirm
            if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
                exit 1
            fi
            ;;
    esac
}

check_space() {
    log_info "Kiem tra dung luong dia..."
    
    # Lay dung luong trong cua partition chua /opt
    if [ -d "/opt" ]; then
        available=$(df /opt | awk 'NR==2 {print $4}')
    else
        available=$(df / | awk 'NR==2 {print $4}')
    fi
    
    if [ -z "$available" ]; then
        log_warning "Khong the xac dinh dung luong trong"
        return 0
    fi
    
    if [ "$available" -lt "$MIN_REQUIRED_SPACE" ]; then
        log_error "Khong du dung luong trong!"
        log_info "Can: $((MIN_REQUIRED_SPACE / 1024)) MB"
        log_info "Co: $((available / 1024)) MB"
        log_info "Vui long giai phong dung luong va thu lai."
        exit 1
    fi
    
    log_success "Du dung luong: $((available / 1024)) MB trong"
}

check_internet() {
    log_step "KIEM TRA KET NOI MANG"
    
    log_info "Kiem tra ket noi internet..."
    
    # Danh sach cac DNS de ping
    DNS_SERVERS="8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9"
    
    for dns in $DNS_SERVERS; do
        if ping -c 1 -W 2 "$dns" >/dev/null 2>&1; then
            log_success "Co ket noi internet (ping $dns thanh cong)"
            return 0
        fi
    done
    
    # Thu curl/wget
    if command -v curl >/dev/null 2>&1; then
        if curl -s --connect-timeout 5 https://google.com >/dev/null 2>&1; then
            log_success "Co ket noi internet (curl thanh cong)"
            return 0
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q --timeout=5 -O- https://google.com >/dev/null 2>&1; then
            log_success "Co ket noi internet (wget thanh cong)"
            return 0
        fi
    fi
    
    log_error "Khong co ket noi internet!"
    log_error "Vui long kiem tra ket noi mang va DNS."
    return 1
}

check_opkg() {
    log_info "Kiem tra trinh quan ly goi opkg..."
    
    if ! command -v opkg >/dev/null 2>&1; then
        log_error "Khong tim thay opkg!"
        log_error "Script nay chi ho tro cac thiet bi chay OpenWrt/Keenetic."
        exit 1
    fi
    
    # Kiem tra opkg hoat dong
    if ! opkg --version >/dev/null 2>&1; then
        log_error "opkg khong hoat dong dung!"
        exit 1
    fi
    
    log_success "opkg san sang"
}

# ============================================
# BACKUP & RESTORE
# ============================================
backup_old_installation() {
    if [ -d "$INSTALL_DIR" ]; then
        log_info "Phat hien cai dat cu tai $INSTALL_DIR"
        
        BACKUP_DIR="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        log_info "Dang backup vao: $BACKUP_DIR"
        
        if cp -r "$INSTALL_DIR" "$BACKUP_DIR" 2>/dev/null; then
            log_success "Backup thanh cong"
            
            # Xoa thu muc cu sau khi backup
            rm -rf "$INSTALL_DIR"
            log_info "Da xoa thu muc cu"
        else
            log_warning "Backup that bai, tiep tuc cai dat moi"
        fi
    fi
}

restore_from_backup() {
    if [ $1 -ne 0 ] && [ -d "$BACKUP_DIR" ]; then
        log_warning "Cai dat that bai, khoi phuc tu backup..."
        if cp -r "$BACKUP_DIR" "$INSTALL_DIR" 2>/dev/null; then
            log_success "Khoi phuc thanh cong"
        else
            log_error "Khong the khoi phuc tu backup"
        fi
    fi
}

# ============================================
# CAI DAT DEPENDENCIES
# ============================================
install_dependencies() {
    log_step "CAI DAT DEPENDENCIES"
    
    local deps=""
    local missing_deps=""
    
    # Kiem tra cac goi can thiet
    for pkg in ca-certificates wget curl; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            missing_deps="$missing_deps $pkg"
        fi
    done
    
    if [ -z "$missing_deps" ]; then
        log_success "Tat ca dependencies da duoc cai dat"
        return 0
    fi
    
    log_info "Cac goi can cai them: $missing_deps"
    
    # Cap nhat package list
    log_info "Cap nhat danh sach goi..."
    if ! opkg update 2>&1 | tee -a "$LOG_FILE" | grep -v "Downloading"; then
        log_error "Khong the cap nhat danh sach goi!"
        return 1
    fi
    
    # Cai dat tung goi
    for pkg in $missing_deps; do
        log_info "Dang cai dat: $pkg..."
        if opkg install "$pkg" 2>&1 | tee -a "$LOG_FILE" | grep -v "Package"; then
            log_success "Da cai $pkg"
        else
            log_warning "Khong the cai $pkg, tiep tuc..."
        fi
    done
    
    return 0
}

# ============================================
# TAI TRUC TIEP (Khong dung Git) - CO RETRY
# ============================================
download_file_with_retry() {
    local file="$1"
    local retry_count=0
    local success=false
    
    while [ $retry_count -lt $MAX_RETRIES ] && [ "$success" = false ]; do
        log_info "Dang tai: $file (lan thu $((retry_count + 1))/$MAX_RETRIES)..."
        
        # Thu wget truoc
        if command -v wget >/dev/null 2>&1; then
            if wget -q --timeout=$TIMEOUT --show-progress "$RAW_URL/$file" 2>&1 | tee -a "$LOG_FILE"; then
                chmod +x "$file" 2>/dev/null || true
                log_success "Da tai: $file"
                success=true
                break
            fi
        fi
        
        # Thu curl neu wget that bai
        if command -v curl >/dev/null 2>&1; then
            if curl -L --connect-timeout $TIMEOUT -s -o "$file" "$RAW_URL/$file" 2>&1 | tee -a "$LOG_FILE"; then
                chmod +x "$file" 2>/dev/null || true
                log_success "Da tai: $file"
                success=true
                break
            fi
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log_warning "Khong the tai $file, thu lai sau ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
        fi
    done
    
    if [ "$success" = false ]; then
        log_error "Khong the tai: $file sau $MAX_RETRIES lan thu"
        return 1
    fi
    return 0
}

download_files() {
    log_step "TAI MA NGUON"
    
    log_info "Tai truc tiep tu GitHub..."
    
    # Tao thu muc cai dat
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || return 1
    
    # Danh sach file can tai
    FILES="install.sh tailscale.sh adguard.sh uninstall.sh"
    local success=true
    
    for file in $FILES; do
        if ! download_file_with_retry "$file"; then
            success=false
            break  # Thoat neu mot file khong tai duoc
        fi
    done
    
    if [ "$success" = true ]; then
        log_success "Tai tat ca file thanh cong"
        return 0
    else
        log_error "Mot so file khong the tai"
        return 1
    fi
}

# ============================================
# CAI DAT CHINH - CO KIEM TRA VONG LAP
# ============================================
run_installer() {
    log_step "BAT DAU CAI DAT CHINH"
    
    cd "$INSTALL_DIR" || {
        log_error "Khong the truy cap $INSTALL_DIR"
        return 1
    }
    
    log_info "Thu muc cai dat: $INSTALL_DIR"
    log_info "Script chinh: install.sh"
    
    # Kiem tra file ton tai va co the doc duoc
    if [ ! -f "install.sh" ]; then
        log_error "Khong tim thay install.sh!"
        return 1
    fi
    
    if [ ! -x "install.sh" ]; then
        log_info "Cap quyen thuc thi..."
        chmod +x install.sh
    fi
    
    # Luu bien moi truong
    export INSTALL_DIR="$INSTALL_DIR"
    export LOG_FILE="$LOG_FILE"
    
    log_info "Bat dau cai dat..."
    echo ""
    
    # Chay script voi xu ly loi va kiem tra vong lap
    local attempt=0
    local max_attempts=2
    local install_success=false
    
    while [ $attempt -lt $max_attempts ] && [ "$install_success" = false ]; do
        attempt=$((attempt + 1))
        log_info "Lan chay cai dat thu $attempt/$max_attempts"
        
        if ./install.sh 2>&1 | tee -a "$LOG_FILE"; then
            install_success=true
            log_success "Script install.sh chay thanh cong!"
            break
        else
            local exit_code=$?
            log_error "Script cai dat chinh that bai voi ma loi: $exit_code"
            
            if [ $attempt -lt $max_attempts ]; then
                log_warning "Se thu lai sau 5 giay..."
                sleep 5
            else
                log_error "Da thu $max_attempts lan nhung that bai!"
                return $exit_code
            fi
        fi
    done
    
    return 0
}

# ============================================
# KIEM TRA SAU CAI DAT
# ============================================
post_install_check() {
    log_step "KIEM TRA SAU CAI DAT"
    
    # Kiem tra dich vu
    local services="tailscale adguardhome"
    local all_ok=true
    
    for svc in $services; do
        if /etc/init.d/"$svc" status >/dev/null 2>&1; then
            log_success "$svc dang chay"
        else
            log_warning "$svc khong chay hoac chua duoc cai dat"
            all_ok=false
        fi
    done
    
    # Hien thi thong tin
    echo ""
    log_info "=== THONG TIN CAI DAT ==="
    echo " Thu muc: $INSTALL_DIR"
    echo " Log: $LOG_FILE"
    
    if [ -f "/etc/config/tailscale" ]; then
        echo " Tailscale: /etc/config/tailscale"
    fi
    
    if [ -f "/etc/config/adguardhome" ]; then
        echo " AdGuard: /etc/config/adguardhome"
    fi
    
    echo ""
}

# ============================================
# XU LY LOI & DON DEP
# ============================================
cleanup() {
    log_info "Don dep..."
    
    # Xoa cac file tam thoi
    find /tmp -name "keenetic-*" -type f -mtime +1 -delete 2>/dev/null || true
    
    log_success "Don dep hoan tat"
}

error_handler() {
    local exit_code=$?
    log_error "Script gap loi tai dong $1"
    log_error "Ma loi: $exit_code"
    
    # Hien thi thong tin debugging
    echo ""
    log_info "=== THONG TIN GO LOI ==="
    echo "OS: $(uname -a)"
    echo "Kernel: $(uname -r)"
    echo "Arch: $(uname -m)"
    echo "Memory: $(free -m | grep Mem | awk '{print $2}') MB"
    
    if [ -f "$LOG_FILE" ]; then
        echo "Log: $LOG_FILE"
        echo "10 dong cuoi log:"
        tail -n 10 "$LOG_FILE"
    fi
    
    exit $exit_code
}

# ============================================
# MAIN - BAT DAU
# ============================================

# Thiet lap trap de bat loi
trap 'error_handler $LINENO' ERR
trap cleanup EXIT

# Khoi tao logging
setup_logging

# Hien thi banner
echo ""
echo "${CYAN}========================================${NC}"
echo "${CYAN}  TAILSCALE + ADGUARD HOME INSTALLER   ${NC}"
echo "${CYAN}  Version: 6.0 - No Git               ${NC}"
echo "${CYAN}  Cho Keenetic Router                 ${NC}"
echo "${CYAN}========================================${NC}"
echo ""

# Kiem tra moi truong
log_step "KIEM TRA MOI TRUONG"
check_root
check_architecture
check_space
check_opkg

# Kiem tra ket noi mang
if ! check_internet; then
    log_error "Khong co ket noi internet!"
    exit 1
fi

# Backup cai dat cu
backup_old_installation

# Cai dat dependencies
if ! install_dependencies; then
    log_error "Khong the cai dat dependencies!"
    exit 1
fi

# Tai ma nguon (khong dung Git)
if ! download_files; then
    log_error "Khong the tai ma nguon!"
    log_error "Vui long kiem tra ket noi va thu lai."
    exit 1
fi

# Chay cai dat
if ! run_installer; then
    log_error "Cai dat that bai!"
    exit 1
fi

# Kiem tra sau cai dat
post_install_check

# Hoan tat
log_step "CAI DAT HOAN TAT"

echo "${GREEN} Cai dat Tailscale va AdGuard Home thanh cong!${NC}"
echo ""
echo "${BLUE} Huong dan tiep theo:${NC}"
echo "   • Kiem tra Tailscale: tailscale status"
echo "   • Kiem tra AdGuard: /etc/init.d/adguardhome status"
echo "   • Xem log: cat $LOG_FILE"
echo ""
echo "${YELLOW} Luu y:${NC}"
echo "   • Khoi dong lai router neu gap van de"
echo "   • Truy cap AdGuard tai: http://$(uci get network.lan.ipaddr 2>/dev/null || echo '192.168.1.1'):3000"
echo "   • Dang nhap Tailscale: tailscale up"
echo ""

# Thoat thanh cong
exit 0
