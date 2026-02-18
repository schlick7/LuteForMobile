#!/data/data/com.termux/files/usr/bin/bash

# MeCab Installation Script for Termux
# This script downloads, compiles, and installs MeCab with IPADIC dictionary

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="$HOME/mecab_install.log"
STATUS_FILE="/storage/emulated/0/Download/mecab_install_status.txt"

# Function to log and display
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to update status
update_status() {
    echo "$1" > "$STATUS_FILE"
    log "${BLUE}[STATUS]${NC} $1"
}

# Function to check if mecab is already installed
check_existing() {
    if command -v mecab &> /dev/null; then
        MECAB_VERSION=$(mecab --version 2>/dev/null | head -n1 || echo "unknown")
        log "${GREEN}✓ MeCab is already installed: $MECAB_VERSION${NC}"
        return 0
    fi
    return 1
}

# Cleanup function
cleanup() {
    log "${YELLOW}Cleaning up temporary files...${NC}"
    cd ~
    rm -rf "$HOME/mecab-0.996.13" 2>/dev/null || true
    rm -f "$HOME/mecab-0.996.13.tar.gz" 2>/dev/null || true
    rm -rf "$HOME/mecab-ipadic-2.7.0-20070801" 2>/dev/null || true
    rm -f "$HOME/mecab-ipadic-2.7.0-20070801.tar.gz" 2>/dev/null || true
}

# Main installation
main() {
    # Clear log
    > "$LOG_FILE"

    update_status "STARTING - MeCab Installation Started"
    log "${BLUE}================================${NC}"
    log "${BLUE}  MeCab Installer for Termux${NC}"
    log "${BLUE}================================${NC}"
    log ""

    # Check if already installed
    if check_existing; then
        update_status "ALREADY_INSTALLED"
        log ""
        log "${GREEN}MeCab is already installed. Exiting.${NC}"
        exit 0
    fi

    # Step 1: Install dependencies
    update_status "STEP_1/5 - Installing build dependencies"
    log ""
    log "${YELLOW}[1/5] Installing build dependencies...${NC}"
    log "This may take a few minutes..."

    # FIXED: Added binutils and libiconv
    if ! pkg install -y build-essential clang make autoconf automake libtool binutils libiconv &>> "$LOG_FILE"; then
        update_status "ERROR - Failed to install dependencies"
        log "${RED}✗ Failed to install dependencies${NC}"
        log "Check log: $LOG_FILE"
        exit 1
    fi
    log "${GREEN}✓ Dependencies installed${NC}"

    # Step 2: Download MeCab
    update_status "STEP_2/5 - Downloading MeCab source"
    log ""
    log "${YELLOW}[2/5] Downloading MeCab...${NC}"

    cd ~
    if ! curl -fsSL -o mecab-0.996.13.tar.gz "https://github.com/shogo82148/mecab/releases/download/v0.996.13/mecab-0.996.13.tar.gz"; then
        update_status "ERROR - Failed to download MeCab"
        log "${RED}✗ Failed to download MeCab${NC}"
        cleanup
        exit 1
    fi

    if [ ! -f "mecab-0.996.13.tar.gz" ] || [ ! -s "mecab-0.996.13.tar.gz" ]; then
        update_status "ERROR - Downloaded file is empty"
        log "${RED}✗ Downloaded file is empty or missing${NC}"
        cleanup
        exit 1
    fi
    log "${GREEN}✓ MeCab downloaded${NC}"

    # Step 3: Extract and build MeCab
    update_status "STEP_3/5 - Building MeCab (this takes 3-5 minutes)"
    log ""
    log "${YELLOW}[3/5] Extracting and building MeCab...${NC}"
    log "This will take 3-5 minutes. Please wait..."

    tar zxf mecab-0.996.13.tar.gz
    cd mecab-0.996.13

    log "  → Configuring..."
    if ! ./configure --prefix=$PREFIX --disable-static &>> "$LOG_FILE"; then
        update_status "ERROR - MeCab configure failed"
        log "${RED}✗ MeCab configuration failed${NC}"
        cleanup
        exit 1
    fi

    log "  → Compiling..."
    if ! make -j$(nproc) &>> "$LOG_FILE"; then
        update_status "ERROR - MeCab compilation failed"
        log "${RED}✗ MeCab compilation failed${NC}"
        cleanup
        exit 1
    fi

    log "  → Installing..."
    if ! make install &>> "$LOG_FILE"; then
        update_status "ERROR - MeCab installation failed"
        log "${RED}✗ MeCab installation failed${NC}"
        cleanup
        exit 1
    fi

    log "${GREEN}✓ MeCab built and installed${NC}"

    # Step 4: Download and install IPADIC dictionary
    update_status "STEP_4/5 - Installing IPADIC dictionary"
    log ""
    log "${YELLOW}[4/5] Downloading IPADIC dictionary...${NC}"

    cd ~
    if ! curl -fsSL -o mecab-ipadic-2.7.0-20070801.tar.gz "https://github.com/shogo82148/mecab/releases/download/v0.996.13/mecab-ipadic-2.7.0-20070801.tar.gz"; then
        update_status "ERROR - Failed to download dictionary"
        log "${RED}✗ Failed to download IPADIC dictionary${NC}"
        cleanup
        exit 1
    fi

    tar zxf mecab-ipadic-2.7.0-20070801.tar.gz
    cd mecab-ipadic-2.7.0-20070801

    log "  → Configuring dictionary..."
    if ! ./configure --prefix=$PREFIX --with-charset=utf8 &>> "$LOG_FILE"; then
        update_status "ERROR - Dictionary configure failed"
        log "${RED}✗ Dictionary configuration failed${NC}"
        cleanup
        exit 1
    fi

    log "  → Installing dictionary..."
    if ! make install &>> "$LOG_FILE"; then
        update_status "ERROR - Dictionary installation failed"
        log "${RED}✗ Dictionary installation failed${NC}"
        cleanup
        exit 1
    fi

    log "${GREEN}✓ IPADIC dictionary installed${NC}"

    # Step 5: Verify installation
    update_status "STEP_5/5 - Verifying installation"
    log ""
    log "${YELLOW}[5/5] Verifying installation...${NC}"

    # Update library path
    export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH

    if ! command -v mecab &> /dev/null; then
        update_status "ERROR - MeCab not found after install"
        log "${RED}✗ MeCab command not found after installation${NC}"
        cleanup
        exit 1
    fi

    # Test mecab with Japanese text
    TEST_RESULT=$(echo "すもももももももものうち" | mecab 2>/dev/null || echo "FAILED")

    if [ "$TEST_RESULT" = "FAILED" ] || [ -z "$TEST_RESULT" ]; then
        update_status "ERROR - MeCab test failed"
        log "${RED}✗ MeCab test failed${NC}"
        cleanup
        exit 1
    fi

    log ""
    log "${GREEN}✓ MeCab is working!${NC}"
    log "Test output:"
    log "$TEST_RESULT"

    # Cleanup
    cleanup

    update_status "COMPLETE - MeCab installation successful"
    log ""
    log "${GREEN}================================${NC}"
    log "${GREEN}  Installation Complete!${NC}"
    log "${GREEN}================================${NC}"
    log ""
    log "MeCab version: $(mecab --version 2>/dev/null | head -n1)"
    log ""
    log "You can now use Japanese text parsing in Lute3."
    log ""
    log "Log saved to: $LOG_FILE"

    exit 0
}

# Run main function
main "$@"
