#!/usr/bin/env bash
# ============================================================================
# Malware Scanner – Omarchy Macchiato (TUI)
# Menu: Scan directory, Update definitions, View log, Exit.
# Auto‑installs clamav if missing.
# ============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# Catppuccin Macchiato – full 24-bit ANSI palette
# ─────────────────────────────────────────────────────────────────────────────
MAUVE=$'\e[38;2;198;160;246m'     # #c6a0f6  – primary accent
LAVENDER=$'\e[38;2;183;189;248m'  # #b7bdf8
BLUE=$'\e[38;2;138;173;244m'      # #8aadf4
TEAL=$'\e[38;2;139;213;202m'      # #8bd5ca
GREEN=$'\e[38;2;166;218;149m'     # #a6da95
YELLOW=$'\e[38;2;238;212;159m'    # #eed49f
PEACH=$'\e[38;2;245;169;127m'     # #f5a97f
RED=$'\e[38;2;237;135;150m'       # #ed8796
TEXT=$'\e[38;2;202;211;245m'      # #cad3f5
SUBTEXT=$'\e[38;2;165;173;206m'   # #a5adce
OVERLAY=$'\e[38;2;110;115;141m'   # #6e738d
BOLD=$'\e[1m'
DIM=$'\e[2m'
ITALIC=$'\e[3m'
RESET=$'\e[0m'

# ─────────────────────────────────────────────────────────────────────────────
# Helpers & UI Logging
# ─────────────────────────────────────────────────────────────────────────────
die() { echo -e "\n  ${RED}✗ ERROR: $*${RESET}" >&2; exit 1; }
info() { echo -e "  ${MAUVE}▶ $*${RESET}"; }
success() { echo -e "  ${GREEN}✓ $*${RESET}"; }
warn() { echo -e "  ${YELLOW}⚠ $*${RESET}"; }

pause() {
    echo -e "\n${OVERLAY}${DIM}  ↵  Press Enter to return to the menu…${RESET}"
    read -r
}

draw_header() {
    clear
    printf '%s' "${MAUVE}${BOLD}"
    cat << 'BANNER'

  ┌─────────────────────────────────────────────────────────────┐
  │ ███╗   ███╗ █████╗ ██╗     ██╗    ██╗ █████╗ ██████╗ ███████╗│
  │ ████╗ ████║██╔══██╗██║     ██║    ██║██╔══██╗██╔══██╗██╔════╝│
  │ ██╔████╔██║███████║██║     ██║ █╗ ██║███████║██████╔╝███████╗│
  │ ██║╚██╔╝██║██╔══██║██║     ██║███╗██║██╔══██║██╔══██╗╚════██║│
  │ ██║ ╚═╝ ██║██║  ██║███████╗╚███╔███╔╝██║  ██║██║  ██║███████║│
  │ ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝│
BANNER
    printf '  │%s' "${RESET}"
    printf '%s' "${SUBTEXT}${ITALIC}"
    printf '         ✦  Omarchy Macchiato  ·  ClamAV Scanner  ✦          '
    printf '%s' "${RESET}${MAUVE}${BOLD}"
    printf '│\n'
    printf '  └─────────────────────────────────────────────────────────────┘\n'
    printf '%s\n' "${RESET}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Core Scanner Functions
# ─────────────────────────────────────────────────────────────────────────────
install_clamav() {
    if ! command -v clamscan &>/dev/null; then
        draw_header
        echo -e "  ${MAUVE}${BOLD}Setup Required${RESET}\n"
        warn "clamscan not found. Installing clamav…"
        sudo pacman -S --noconfirm clamav || die "Failed to install ClamAV."
        success "ClamAV installed."
        info "Run 'Update Virus Definitions' to fetch the latest signatures."
        sleep 2
    fi
}

update_definitions() {
    draw_header
    echo -e "  ${MAUVE}${BOLD}Update Definitions${RESET}\n"
    info "Updating virus definitions via freshclam…"
    if ! command -v freshclam &>/dev/null; then
        warn "freshclam not found. Try reinstalling ClamAV."
        pause
        return
    fi
    sudo freshclam
    echo
    success "Definitions updated."
    pause
}

view_log() {
    draw_header
    echo -e "  ${MAUVE}${BOLD}Scan Logs${RESET}\n"
    local latest_log=$(ls -t /tmp/clamscan_*.log 2>/dev/null | head -1)
    if [[ -z "$latest_log" ]]; then
        warn "No scan logs found. Run a scan first."
        pause
        return
    fi
    info "Last scan log: ${TEXT}${latest_log}${RESET}\n"
    cat "$latest_log"
    echo -e "\n  ${OVERLAY}${DIM}--- end of log ---${RESET}"
    pause
}

scan_directory() {
    draw_header
    echo -e "  ${MAUVE}${BOLD}Target Selection${RESET}\n"
    
    echo -ne "  ${MAUVE}❯ ${RESET}${TEXT}Enter directory to scan (full path): "
    read -r dir
    
    if [[ -z "$dir" ]]; then
        warn "No directory entered."
        pause
        return
    fi
    if [[ ! -d "$dir" ]]; then
        warn "Directory does not exist: $dir"
        pause
        return
    fi

    echo -ne "  ${MAUVE}❯ ${RESET}${TEXT}Remove infected files automatically? (y/N): "
    read -r remove_choice
    local remove_flag=""
    
    echo
    if [[ "$remove_choice" =~ ^[Yy]$ ]]; then
        remove_flag="--remove=yes"
        echo -e "  ${RED}${BOLD}⚠  Infected files will be DELETED!${RESET}"
    else
        remove_flag=""
        echo -e "  ${GREEN}✓ Safe mode enabled: only reporting, no deletion.${RESET}"
    fi

    local logfile="/tmp/clamscan_$(date +%Y%m%d_%H%M%S).log"
    echo -e "\n  ${MAUVE}▶ Scanning: ${TEXT}$dir …${RESET}\n"

    # Run clamscan with real‑time output
    sudo clamscan --recursive --infected $remove_flag --log="$logfile" "$dir" 2>&1 | tee -a /dev/tty

    # Show summary safely without tripping pipeline errors
    local infected=$(grep -c "FOUND$" "$logfile" 2>/dev/null || true)
    [[ -z "$infected" ]] && infected="0"
    
    local scanned=$(grep "Scanned files:" "$logfile" | head -1 | grep -oP '\d+' || echo "?")

    echo -e "\n  ${MAUVE}${BOLD}Scan Complete${RESET}"
    echo -e "  ${OVERLAY}╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌${RESET}"
    if [[ "$infected" -eq 0 ]]; then
        echo -e "    ${GREEN}✅ Status: No malware found.${RESET}"
    else
        echo -e "    ${RED}❌ Status: $infected infected file(s) found.${RESET}"
        echo -e "    ${SUBTEXT}${DIM}See $logfile for details.${RESET}"
    fi
    echo -e "    ${TEXT}Files Scanned:${RESET} $scanned"
    pause
}

# ─────────────────────────────────────────────────────────────────────────────
# Main Loop
# ─────────────────────────────────────────────────────────────────────────────
main_menu() {
    install_clamav
    
    while true; do
        draw_header
        
        echo -e "  ${MAUVE}${BOLD}  Scanner Operations${RESET}"
        echo -e "  ${OVERLAY}  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌${RESET}"
        echo
        echo -e "    ${LAVENDER}${BOLD}1${RESET}  ${TEXT}📂 Scan a Directory${RESET}"
        echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}Search for malware in a specific folder${RESET}"
        echo
        echo -e "    ${LAVENDER}${BOLD}2${RESET}  ${TEXT}🔄 Update Virus Definitions${RESET}"
        echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}Run freshclam to get the latest signatures${RESET}"
        echo
        echo -e "    ${LAVENDER}${BOLD}3${RESET}  ${TEXT}📄 View Last Scan Log${RESET}"
        echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}Check results from the previous scan${RESET}"
        echo
        echo -e "    ${RED}${BOLD}0${RESET}  ${TEXT}🚪 Exit${RESET}"
        echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}Close scanner${RESET}"
        echo
        echo -e "  ${OVERLAY}  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌${RESET}"
        
        echo -ne "\n  ${MAUVE}❯ ${RESET}${TEXT}"
        read -r choice
        printf '%s' "${RESET}"

        case $choice in
            1) scan_directory ;;
            2) update_definitions ;;
            3) view_log ;;
            0) clear; echo -e "\n  ${MAUVE}${BOLD}  Goodbye! ✦${RESET}\n"; exit 0 ;;
            *) warn "Invalid option."; sleep 1 ;;
        esac
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Run
# ─────────────────────────────────────────────────────────────────────────────
main_menu