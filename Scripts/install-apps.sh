#!/usr/bin/env bash
set -euo pipefail

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[1;35m'
BLUE=$'\033[1;34m'
WHITE=$'\033[1;37m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

if [[ $EUID -eq 0 ]]; then
    echo "${RED}ERROR: Do not run this script as root. Run as a normal user (sudo will prompt).${NC}"
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    echo "${RED}ERROR: pacman not found. This script only supports Arch Linux.${NC}"
    exit 1
fi

if ! sudo -v; then
    echo "${RED}ERROR: sudo required.${NC}"
    exit 1
fi
( while true; do sudo -n true 2>/dev/null || break; sleep 60; done ) &

show_banner() {
    clear
    printf "${CYAN}${BOLD}"
    printf "  ██████╗ ███╗   ███╗ █████╗ ██████╗  ██████╗██╗  ██╗██╗   ██╗\n"
    printf " ██╔═══██╗████╗ ████║██╔══██╗██╔══██╗██╔════╝██║  ██║╚██╗ ██╔╝\n"
    printf " ██║   ██║██╔████╔██║███████║██████╔╝██║     ███████║ ╚████╔╝ \n"
    printf " ██║   ██║██║╚██╔╝██║██╔══██║██╔══██╗██║     ██╔══██║  ╚██╔╝  \n"
    printf " ╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╗██║  ██║   ██║   \n"
    printf "  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   \n"
    printf "${NC}\n"
    printf "${MAGENTA}${BOLD}        O M A R C H Y   A P P   I N S T A L L E R        ${NC}\n"
    printf "============================================================\n\n"
}

animate_progress() {
    local pid=$1 app_name=$2
    local delay=0.15 progress=0 bar_length=30 filled empty bar space i full_bar
    tput civis 2>/dev/null || true

    while kill -0 "$pid" 2>/dev/null; do
        progress=$((progress + 1))
        (( progress >= 99 )) && progress=99
        filled=$(( progress * bar_length / 100 ))
        empty=$(( bar_length - filled ))
        bar=""
        space=""
        for ((i=0; i<filled; i++)); do bar="${bar}█"; done
        for ((i=0; i<empty; i++)); do space="${space}░"; done
        printf "\r${CYAN}Downloading: ${WHITE}%-22s ${YELLOW}[${GREEN}%s${WHITE}%s${YELLOW}] ${CYAN}%3d%%${NC}" \
            "$app_name" "$bar" "$space" "$progress"
        sleep "$delay"
    done

    wait "$pid" 2>/dev/null
    local rc=$?

    full_bar=""
    for ((i=0; i<bar_length; i++)); do full_bar="${full_bar}█"; done

    if (( rc == 0 )); then
        printf "\r\e[K${GREEN}[✔] Installed: ${BOLD}%-24s ${YELLOW}[${GREEN}%s${YELLOW}] ${CYAN}100%%${NC}\n" \
            "$app_name" "$full_bar"
    else
        printf "\r\e[K${RED}[✘] FAILED: ${BOLD}%-24s ${YELLOW}[${RED}%s${YELLOW}]${NC}\n" \
            "$app_name" "$bar"
    fi

    tput cnorm 2>/dev/null || true
    return $rc
}

install_one() {
    local label=$1 cmd=$2 pkg=$3
    local log pid rc
    log=$(mktemp)

    case "$cmd" in
        pacman)
            if pm_installed "$pkg"; then
                printf "${DIM}  %s (already installed)${NC}\n" "$label"
                rm -f "$log"; return 0
            fi
            (sudo pacman -S --needed --noconfirm "$pkg" >"$log" 2>&1) &
            ;;
        aur)
            if pm_installed "$pkg"; then
                printf "${DIM}  %s (already installed)${NC}\n" "$label"
                rm -f "$log"; return 0
            fi
            (yay -S --needed --noconfirm "$pkg" >"$log" 2>&1) &
            ;;
        flatpak)
            if fp_installed "$pkg"; then
                printf "${DIM}  %s (already installed)${NC}\n" "$label"
                rm -f "$log"; return 0
            fi
            (flatpak install --user -y flathub "$pkg" >"$log" 2>&1) &
            ;;
        brave)
            if command -v brave-origin &>/dev/null || [[ -d /opt/brave-origin ]]; then
                printf "${DIM}  %s (already installed)${NC}\n" "$label"
                rm -f "$log"; return 0
            fi
            (curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh >"$log" 2>&1) &
            ;;
        *)
            rm -f "$log"; return 0
            ;;
    esac

    pid=$!
    animate_progress "$pid" "$label"
    rc=$?

    if (( rc != 0 )); then
        printf "${RED}    Log tail:${NC}\n"
        tail -n 8 "$log" | sed 's/^/    /'
    fi
    rm -f "$log"
    return $rc
}

ensure_yay() {
    if command -v yay &>/dev/null; then return 0; fi
    install_one "AUR helper deps" pacman "base-devel" || true
    install_one "git" pacman "git" || true
    local log pid rc
    log=$(mktemp)
    ( git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin \
        && cd /tmp/yay-bin && makepkg -si --noconfirm \
        && rm -rf /tmp/yay-bin >"$log" 2>&1 ) &
    pid=$!
    animate_progress "$pid" "yay (AUR helper)"
    rc=$?
    if (( rc != 0 )); then tail -n 8 "$log"; fi
    rm -f "$log"
    return $rc
}

FLATPAK_IDS=(
    io.github.peazip.PeaZip
    com.stremio.Stremio
    io.github.kolunmi.Bazaar
    fr.handbrake.ghb
    io.github.linx_systems.ClamUI
    io.github.flattool.Warehouse
    com.super_productivity.SuperProductivity
    org.onlyoffice.desktopeditors
    org.upscayl.Upscayl
    io.github.vmkspv.lenspect
    com.notesnook.Notesnook
    com.github.ADBeveridge.Raider
    io.github.ecotubehq.player
)
FLATPAK_NAMES=(
    "PeaZip"
    "Stremio"
    "Bazaar"
    "HandBrake"
    "ClamUI"
    "Warehouse"
    "Super Productivity"
    "OnlyOffice"
    "Upscayl"
    "Lenspect"
    "Notesnook"
    "Raider"
    "EcoTubeHQ"
)
PACMAN_APPS=(flatpak flatseal thunderbird mat2 gnome-clocks gnome-text-editor blanket anki nwg-look)
PACMAN_NAMES=(
    "Flatpak"
    "Flatseal"
    "Thunderbird"
    "MAT2"
    "GNOME Clocks"
    "GNOME Text Editor"
    "Blanket"
    "Anki"
    "nwg-look"
)
AUR_APPS=(gearlever qbittorrent-git cryptomator-bin grayjay keypunch-git tor-browser-bin)
AUR_NAMES=(
    "Gear Lever"
    "qBittorrent"
    "Cryptomator"
    "Grayjay"
    "Keypunch"
    "Tor Browser"
)

fp_installed() { flatpak info "$1" &>/dev/null; }
pm_installed() { pacman -Q "$1" &>/dev/null; }

flatpak_setup() {
    if ! command -v flatpak &>/dev/null; then
        install_one "Flatpak runtime" pacman "flatpak" || true
    fi
    flatpak remote-add --if-not-exists --user flathub \
        https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
}

disable_recents() {
    printf "${CYAN}============================================================${NC}\n"
    printf "${CYAN}  Disabling file-manager recent history (Nautilus + GTK)${NC}\n"
    printf "${CYAN}============================================================${NC}\n"
    if command -v gsettings &>/dev/null; then
        printf ">>> Turning off recent-files tracking...\n"
        gsettings set org.gnome.desktop.privacy remember-recent-files false
        gsettings set org.gnome.nautilus show-recent false 2>/dev/null || true
        gsettings set org.gnome.desktop.privacy remove-old-trash-files true
        gsettings set org.gnome.desktop.privacy remove-old-temp-files true
        printf "${GREEN}    OK: privacy settings applied.${NC}\n"
    else
        printf "${YELLOW}    gsettings not found, skipping.${NC}\n"
    fi
    printf ">>> Purging stored file history...\n"
    rm -f "$HOME/.local/share/recently-used.xbel"
    rm -f "$HOME/.local/share/recently-used.xbel.bak"
    printf "${GREEN}    OK: history files removed.${NC}\n"
    printf "${DIM}    Note: this hides 'Recent' from Nautilus and clears past entries.${NC}\n"
}

install_all() {
    printf "\n${BOLD}${CYAN}--- Starting Bulk Installation ---${NC}\n\n"
    ensure_yay
    flatpak_setup

    printf "${MAGENTA}>> Official Repository Apps (Pacman)${NC}\n"
    for i in "${!PACMAN_APPS[@]}"; do
        install_one "${PACMAN_NAMES[$i]}" pacman "${PACMAN_APPS[$i]}" || true
    done

    printf "${MAGENTA}>> Flatpak Apps${NC}\n"
    for i in "${!FLATPAK_IDS[@]}"; do
        install_one "${FLATPAK_NAMES[$i]}" flatpak "${FLATPAK_IDS[$i]}" || true
    done

    printf "${MAGENTA}>> AUR Apps${NC}\n"
    for i in "${!AUR_APPS[@]}"; do
        install_one "${AUR_NAMES[$i]}" aur "${AUR_APPS[$i]}" || true
    done

    printf "${MAGENTA}>> Official Installer${NC}\n"
    install_one "Brave Origin" brave "" || true

    printf "\n${GREEN}${BOLD}All applications installed!${NC}\n"
}

menu_all() {
    local n=1
    printf "${MAGENTA}>> Flatpak Apps${NC}\n"
    for name in "${FLATPAK_NAMES[@]}"; do
        printf '  %2d) %s\n' "$n" "$name"; n=$((n+1))
    done
    printf "${MAGENTA}>> Official Repository Apps${NC}\n"
    for name in "${PACMAN_NAMES[@]}"; do
        printf '  %2d) %s\n' "$n" "$name"; n=$((n+1))
    done
    printf "${MAGENTA}>> AUR Apps${NC}\n"
    for name in "${AUR_NAMES[@]}"; do
        printf '  %2d) %s\n' "$n" "$name"; n=$((n+1))
    done
    printf "${MAGENTA}>> Official Installer${NC}\n"
    printf '  %2d) Brave Origin\n' "$n"
}

install_selected() {
    local sel
    read -rp "> Pick numbers (comma-separated): " sel
    [[ -z "$sel" ]] && return 0
    local -a picks=()
    IFS=', ' read -r -a picks <<< "$sel"

    local -a jobs=()
    local p idx
    for p in "${picks[@]}"; do
        if [[ "$p" =~ ^[0-9]+$ ]] && (( p >= 1 && p <= 29 )); then
            if (( p <= 13 )); then
                idx=$((p-1)); jobs+=("${FLATPAK_NAMES[$idx]}|flatpak|${FLATPAK_IDS[$idx]}")
            elif (( p <= 22 )); then
                idx=$((p-14)); jobs+=("${PACMAN_NAMES[$idx]}|pacman|${PACMAN_APPS[$idx]}")
            elif (( p == 29 )); then
                jobs+=("Brave Origin|brave|")
            else
                idx=$((p-23)); jobs+=("${AUR_NAMES[$idx]}|aur|${AUR_APPS[$idx]}")
            fi
        else
            printf "${YELLOW}  ignoring invalid: %s${NC}\n" "$p"
        fi
    done

    if [[ ${#jobs[@]} -gt 0 ]]; then
        ensure_yay
        flatpak_setup
    fi

    printf "\n${BOLD}${CYAN}--- Installing selected apps ---${NC}\n\n"
    local job label cmd pkg
    for job in "${jobs[@]}"; do
        IFS='|' read -r label cmd pkg <<< "$job"
        install_one "$label" "$cmd" "$pkg" || true
    done
    printf "\n${GREEN}${BOLD}Done!${NC}\n"
}

main() {
    while true; do
        show_banner
        echo -e "  ${BOLD}Please choose an option:${NC}\n"
        echo -e "  ${CYAN}[1]${NC} Install All Apps (Automated)"
        echo -e "  ${CYAN}[2]${NC} Select Manually Which App to Install"
        echo -e "  ${CYAN}[3]${NC} Disable 'Recent' Tab in File Manager"
        echo -e "  ${RED}[q]${NC} Exit"
        echo -e "================================================================\n"

        local opt
        read -rp "Enter your choice (1-3 or q): " opt
        case "${opt,,}" in
            1) install_all ;;
            2) menu_all; install_selected ;;
            3) disable_recents ;;
            q|quit) echo -e "\n${GREEN}Goodbye!${NC}\n"; exit 0 ;;
            *) echo -e "\n${RED}Invalid option.${NC}"; sleep 1 ;;
        esac
    done
}

main "$@"
