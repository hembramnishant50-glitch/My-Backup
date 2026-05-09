#!/usr/bin/env bash
# ============================================================================
# YouTube Downloader – Omarchy Edition (Arch / Hyprland)
# - UI matching Omarchy Macchiato tree-style
# - Supports cookies for age‑restricted videos
# - Live progress display
# ============================================================================

set -euo pipefail

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
# Configuration
# ─────────────────────────────────────────────────────────────────────────────
DOWNLOAD_DIR="$HOME/Downloads/YouTube"
DEFAULT_COOKIE_FILE="$HOME/.config/yt-dlp/cookies.txt"
CUSTOM_COOKIE_FILE=""
COOKIE_OPT=""

mkdir -p "$DOWNLOAD_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
pause() {
    echo -e "\n${OVERLAY}${DIM}  ↵  Press Enter to continue…${RESET}"
    read -r
}

draw_header() {
    clear
    printf '%s' "${MAUVE}${BOLD}"
    cat << 'BANNER'

  ┌─────────────────────────────────────────────────────────────┐
  │  ██╗   ██╗████████╗██████╗ ██╗      ██████╗  ██████╗ ██████╗ │
  │  ╚██╗ ██╔╝╚══██╔══╝██╔══██╗██║     ██╔═══██╗██╔═══██╗██╔══██╗│
  │   ╚████╔╝    ██║   ██████╔╝██║     ██║   ██║██║   ██║██████╔╝│
  │    ╚██╔╝     ██║   ██╔═══╝ ██║     ██║   ██║██║   ██║██╔═══╝ │
  │     ██║      ██║   ██║     ███████╗╚██████╔╝╚██████╔╝██║     │
  │     ╚═╝      ╚═╝   ╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝     │
BANNER
    printf '  │%s' "${RESET}"
    printf '%s' "${SUBTEXT}${ITALIC}"
    printf '       ✦  Omarchy Macchiato  ·  YouTube Downloader  ✦        '
    printf '%s' "${RESET}${MAUVE}${BOLD}"
    printf '│\n'
    printf '  └─────────────────────────────────────────────────────────────┘\n'
    printf '%s\n' "${RESET}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Dependency check
# ─────────────────────────────────────────────────────────────────────────────
check_deps() {
    local missing=()
    for cmd in yt-dlp ffmpeg; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "\n  ${RED}✗ Missing dependencies: ${missing[*]}${RESET}"
        echo -e "  ${SUBTEXT}Install with: ${MAUVE}sudo pacman -S ${missing[*]}${RESET}"
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Set cookie option
# ─────────────────────────────────────────────────────────────────────────────
set_cookie_opt() {
    COOKIE_OPT=""
    if [[ -n "$CUSTOM_COOKIE_FILE" && -f "$CUSTOM_COOKIE_FILE" ]]; then
        COOKIE_OPT="--cookies $CUSTOM_COOKIE_FILE"
    elif [[ -f "$DEFAULT_COOKIE_FILE" ]]; then
        COOKIE_OPT="--cookies $DEFAULT_COOKIE_FILE"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Cookie menu
# ─────────────────────────────────────────────────────────────────────────────
cookie_menu() {
    draw_header
    echo -e "  ${MAUVE}${BOLD}🍪  Cookie Settings${RESET}"
    echo -e "  ${OVERLAY}  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌${RESET}"
    echo
    echo -e "    ${LAVENDER}${BOLD}1${RESET}  ${TEXT}Use default profile${RESET}"
    echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}~/.config/yt-dlp/cookies.txt${RESET}"
    echo
    echo -e "    ${LAVENDER}${BOLD}2${RESET}  ${TEXT}Specify custom path${RESET}"
    echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}Enter a custom cookies.txt location${RESET}"
    echo
    echo -e "    ${RED}${BOLD}0${RESET}  ${TEXT}↩  Back${RESET}"
    echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}Return to main menu${RESET}"
    echo
    echo -e "  ${OVERLAY}  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌${RESET}"
    echo -ne "\n  ${MAUVE}❯ ${RESET}${TEXT}"
    read -r choice
    printf '%s' "${RESET}"

    case $choice in
        1)
            CUSTOM_COOKIE_FILE=""
            set_cookie_opt
            echo -e "\n  ${GREEN}✓ Using default cookies${RESET}"
            ;;
        2)
            echo -ne "\n  ${MAUVE}Enter full path to cookies.txt: ${RESET}${TEXT}"
            read -r path
            printf '%s' "${RESET}"
            if [[ -n "$path" && -f "$path" ]]; then
                CUSTOM_COOKIE_FILE="$path"
                set_cookie_opt
                echo -e "\n  ${GREEN}✓ Using custom cookies: $path${RESET}"
            else
                echo -e "\n  ${RED}✗ File not found. Keeping previous settings.${RESET}"
            fi
            ;;
        0) return ;;
        *) echo -e "\n  ${RED}✗ Invalid option.${RESET}" ;;
    esac
    pause
}

# ─────────────────────────────────────────────────────────────────────────────
# Download with live progress
# ─────────────────────────────────────────────────────────────────────────────
download_video() {
    local url="$1"
    local format="$2"
    local ext="$3"
    local merge_opts="$4"

    echo -e "\n  ${MAUVE}Fetching video info…${RESET}"
    local title
    title=$(yt-dlp $COOKIE_OPT --print "%(title)s" "$url" 2>/dev/null | head -n1 | sed 's/[\/:*?"<>|]/_/g')
    if [[ -z "$title" ]]; then
        echo -e "  ${RED}✗ Failed to fetch video info. Check URL or cookies.${RESET}"
        pause
        return 1
    fi
    echo -e "  ${GREEN}✓ Title:${RESET} ${TEXT}$title${RESET}"

    local output="$DOWNLOAD_DIR/${title}.$ext"
    local log="/tmp/yt_dl_$$.log"

    echo -e "\n  ${MAUVE}Starting download…${RESET}"
    
    (
        yt-dlp $COOKIE_OPT $merge_opts -f "$format" --newline --progress -o "$output" "$url" &> "$log"
    ) &
    local pid=$!

    echo -e "\n  ${SUBTEXT}${DIM}Progress (press Ctrl+C to cancel, download continues in background):${RESET}\n"
    tail -f "$log" 2>/dev/null &
    local tail_pid=$!
    wait $pid 2>/dev/null
    kill $tail_pid 2>/dev/null

    if [[ $? -eq 0 ]]; then
        echo -e "\n  ${GREEN}✓ Download completed!${RESET}"
        echo -e "  ${SUBTEXT}${DIM}Saved to: $output${RESET}"
    else
        echo -e "\n  ${RED}✗ Download failed. Check log: $log${RESET}"
    fi
    pause
}

# ─────────────────────────────────────────────────────────────────────────────
# Main menu
# ─────────────────────────────────────────────────────────────────────────────
main_menu() {
    set_cookie_opt

    while true; do
        draw_header
        
        # Info Block
        echo -e "  ${MAUVE}${BOLD}  Status Info${RESET}"
        echo -e "  ${OVERLAY}  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌${RESET}"
        echo -e "    ${TEXT}📁 Directory:${RESET} ${SUBTEXT}$DOWNLOAD_DIR${RESET}"
        if [[ -n "$COOKIE_OPT" ]]; then
            echo -e "    ${TEXT}🍪 Cookies:  ${RESET} ${GREEN}Enabled${RESET}"
        else
            echo -e "    ${TEXT}🍪 Cookies:  ${RESET} ${YELLOW}None (age-restricted videos will fail)${RESET}"
        fi
        echo

        # Menu
        echo -e "  ${MAUVE}${BOLD}  Download Options${RESET}"
        echo -e "  ${OVERLAY}  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌${RESET}"
        echo
        echo -e "    ${LAVENDER}${BOLD}1${RESET}  ${TEXT}🎬 Video + Audio${RESET}"
        echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}Best quality (MP4)${RESET}"
        echo
        echo -e "    ${LAVENDER}${BOLD}2${RESET}  ${TEXT}🎵 Audio Only${RESET}"
        echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}Best quality (M4A)${RESET}"
        echo
        echo -e "    ${LAVENDER}${BOLD}3${RESET}  ${TEXT}🎞️  Video Only${RESET}"
        echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}No audio track (MP4)${RESET}"
        echo
        echo -e "    ${LAVENDER}${BOLD}4${RESET}  ${TEXT}⚙️  Cookie Settings${RESET}"
        echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}Change authorization source${RESET}"
        echo
        echo -e "    ${RED}${BOLD}0${RESET}  ${TEXT}🚪 Exit${RESET}"
        echo -e "       ${OVERLAY}╰─ ${SUBTEXT}${DIM}Close downloader${RESET}"
        echo
        echo -e "  ${OVERLAY}  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌${RESET}"
        echo -ne "\n  ${MAUVE}❯ ${RESET}${TEXT}"
        read -r choice
        printf '%s' "${RESET}"

        case $choice in
            1) format="bestvideo+bestaudio/best"; ext="mp4"; merge_opts="--merge-output-format mp4" ;;
            2) format="bestaudio"; ext="m4a"; merge_opts="--extract-audio --audio-format m4a" ;;
            3) format="bestvideo"; ext="mp4"; merge_opts="" ;;
            4) cookie_menu; continue ;;
            0) clear; echo -e "\n  ${MAUVE}${BOLD}  Goodbye! ✦${RESET}\n"; exit 0 ;;
            *) echo -e "\n  ${RED}✗ Invalid option.${RESET}"; sleep 0.8; continue ;;
        esac

        # Only reach here for download options 1-3
        echo -ne "\n  ${MAUVE}Enter YouTube URL: ${RESET}${TEXT}"
        read -r url
        printf '%s' "${RESET}"
        [[ -z "$url" ]] && continue

        download_video "$url" "$format" "$ext" "$merge_opts"
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Run
# ─────────────────────────────────────────────────────────────────────────────
check_deps
main_menu