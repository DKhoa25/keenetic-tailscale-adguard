#!/bin/sh
# ============================================
# DOWNLOAD MODULE WITH RETRY
# ============================================

download_file_with_retry() {
    local file="$1"
    local retry_count=0
    local success=false
    
    while [ $retry_count -lt $MAX_RETRIES ] && [ "$success" = false ]; do
        log_info "Đang tải: $file (lần thử $((retry_count + 1))/$MAX_RETRIES)..."
        
        if command -v wget >/dev/null 2>&1; then
            if wget -q --timeout=$TIMEOUT --show-progress "$RAW_URL/$file" 2>&1 | tee -a "$LOG_FILE"; then
                chmod +x "$file" 2>/dev/null || true
                log_success "Đã tải: $file"
                success=true
                break
            fi
        fi
        
        if command -v curl >/dev/null 2>&1; then
            if curl -L --connect-timeout $TIMEOUT -s -o "$file" "$RAW_URL/$file" 2>&1 | tee -a "$LOG_FILE"; then
                chmod +x "$file" 2>/dev/null || true
                log_success "Đã tải: $file"
                success=true
                break
            fi
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log_warning "Không thể tải $file, thử lại sau ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
        fi
    done
    
    if [ "$success" = false ]; then
        log_error "Không thể tải: $file sau $MAX_RETRIES lần thử"
        return 1
    fi
    return 0
}

download_files() {
    log_step "TẢI MÃ NGUỒN"
    
    log_info "Tải trực tiếp từ GitHub..."
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || return 1
    
    FILES="install.sh tailscale.sh adguard.sh uninstall.sh"
    local success=true
    
    for file in $FILES; do
        if ! download_file_with_retry "$file"; then
            success=false
            break
        fi
    done
    
    if [ "$success" = true ]; then
        log_success "Tải tất cả file thành công"
        return 0
    else
        log_error "Một số file không thể tải"
        return 1
    fi
}
