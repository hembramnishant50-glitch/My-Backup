#!/bin/bash

# ==============================================================================
# OMARCHT APP INSTALLER SCRIPT
# Easy to edit: Add or remove apps from the arrays below.
# ==============================================================================

# --- APP LISTS (EDIT THESE ARRAYS TO ADD/REMOVE APPS) ---

# Apps to install using 'yay'
YAY_APPS=(
    "ayugram-desktop-bin"
    "nwg-look"
    "cryptomator-bin"
    "keypunch-git"
    "lenspect"
    "megabasterd-bin"
    "helium-browser-bin"
    "peazip-gtk2-bin"
)

# Apps to install using 'sudo pacman'
PACMAN_APPS=(
    "bleachbit"
    "obsidian"
    "blanket"
    "handbrake"
    "qbittorrent"
    "torbrowser-launcher"
    "metadata-cleaner"
    "collision"
    "nautilus-python"
    "gedit"
    "gedit-plugins"
    "flatpak"
)

# Apps to install using 'flatpak'
FLATPAK_APPS=(
    "io.gitlab.theevilskeleton.Upscaler"
    "io.gitlab.adhami3310.Converter"
    "org.gnome.gitlab.YaLTeR.VideoTrimmer"
    "fr.handbrake.ghb"
    "org.bunkus.mkvtoolnix-gui"
    "io.github.AshBuk.FingerGo"
    "app.drey.Dialect"
    "io.github.flattool.Warehouse"
    "net.nokyan.Resources"
    "io.github.linx_systems.ClamUI"
    "io.github.vmkspv.lenspect"
    "com.github.tenderowl.frog"
    "io.github.kolunmi.Bazaar"
    "io.github.fabrialberio.pinapp"
    "de.swsnr.keepmeawake"
)

# ==============================================================================
# UI COLORS & STYLING
# ==============================================================================
RESET="\e[0m"
BOLD="\e[1m"
CYAN="\e[1;36m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"
WHITE="\e[1;37m"

# ==============================================================================
# INITIALIZATION & DEPENDENCIES
# ==============================================================================

# 1. Ask for Sudo Permissions Upfront
clear
echo -e "${CYAN}${BOLD}Requesting Administrator Privileges...${RESET}"
sudo -v
# Keep sudo alive in the background while the script runs
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 2. Setup Flatpak Flathub Repository (Dependency for Flatpaks)
echo -e "${YELLOW}Checking and initializing core dependencies...${RESET}"
sudo pacman -S flatpak --noconfirm >/dev/null 2>&1
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Display a beautiful big ASCII Banner
show_banner() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    echo "  ███████╗███╗   ███╗ █████╗ ██████╗ ████████╗███████╗"
    echo "  ██╔════╝████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝"
    echo "  ███████╗██╔████╔██║███████║██████╔╝   ██║   ███████╗"
    echo "  ╚════██║██║╚██╔╝██║██╔══██║██╔══██╗   ██║   ╚════██║"
    echo "  ███████║██║ ╚═╝ ██║██║  ██║██║  ██║   ██║   ███████║"
    echo "  ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝"
    echo -e "${CYAN}        O M A R C H T   A P P   I N S T A L L E R       ${RESET}"
    echo -e "================================================================${RESET}\n"
}

# The Long Bar Downloading Animation (Pills/Rounded Style)
animate_progress() {
    local pid=$1
    local app_name=$2
    local delay=0.15      # Speed of the progress bar
    local progress=0      # Starting percentage
    local bar_length=30   # Length of the progress bar

    # Hide cursor
    tput civis
    
    # Loop while the installation process is still running
    while kill -0 "$pid" 2>/dev/null; do
        progress=$((progress + 1))
        # Cap the fake progress at 99% until the process actually finishes
        if [ "$progress" -ge 99 ]; then 
            progress=99 
        fi
        
        # Calculate filled and empty chunks of the bar
        local filled=$(( (progress * bar_length) / 100 ))
        local empty=$(( bar_length - filled ))
        
        # Build the bar strings using rounded/pill block characters
        local bar=""
        local space=""
        for ((i=0; i<filled; i++)); do bar="${bar}▰"; done
        for ((i=0; i<empty; i++)); do space="${space}▱"; done
        
        # Print the animation line with carriage return (\r) to overwrite the same line
        printf "\r${CYAN}Downloading: ${WHITE}%-22s ${YELLOW}[${GREEN}%s${WHITE}%s${YELLOW}] ${CYAN}%3d%%${RESET}" "$app_name" "$bar" "$space" "$progress"
        
        sleep "$delay"
    done
    
    # Process is done, jump to 100% and fill the bar completely
    local full_bar=""
    for ((i=0; i<bar_length; i++)); do full_bar="${full_bar}▰"; done
    
    # \e[K clears the rest of the line to ensure no leftover artifacts
    printf "\r\e[K${GREEN}[✔] Installed: ${BOLD}%-24s ${YELLOW}[${GREEN}%s${YELLOW}] ${CYAN}100%%${RESET}\n" "$app_name" "$full_bar"
    
    # Restore cursor
    tput cnorm
}

# Unified Installation Function
install_package() {
    local package_manager=$1
    local app=$2
    
    if [ "$package_manager" == "yay" ]; then
        yay -S "$app" --noconfirm >/dev/null 2>&1 &
        animate_progress $! "$app"
    
    elif [ "$package_manager" == "pacman" ]; then
        sudo pacman -S "$app" --noconfirm >/dev/null 2>&1 &
        animate_progress $! "$app"
    
    elif [ "$package_manager" == "flatpak" ]; then
        flatpak install flathub "$app" -y >/dev/null 2>&1 &
        animate_progress $! "$app"
    fi
}

# Option 1: Install all apps automatically
install_all() {
    echo -e "\n${BOLD}${CYAN}--- Starting Bulk Installation ---${RESET}\n"
    
    for app in "${PACMAN_APPS[@]}"; do
        install_package "pacman" "$app"
    done
    
    for app in "${YAY_APPS[@]}"; do
        install_package "yay" "$app"
    done
    
    for app in "${FLATPAK_APPS[@]}"; do
        install_package "flatpak" "$app"
    done
    
    echo -e "\n${GREEN}${BOLD}All applications have been installed!${RESET}"
    read -p "Press Enter to return to menu..."
}

# Option 2: Manually select apps to install
install_manual() {
    echo -e "\n${BOLD}${CYAN}--- Manual Installation Mode ---${RESET}"
    echo -e "${YELLOW}Type 'y' to install, or 'n' to skip.${RESET}\n"
    
    # Pacman manual
    echo -e "${MAGENTA}>> Official Repository Apps (Pacman)${RESET}"
    for app in "${PACMAN_APPS[@]}"; do
        read -p "$(echo -e "Install ${BOLD}$app${RESET}? (y/n): ")" choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            install_package "pacman" "$app"
        fi
    done
    
    # Yay manual
    echo -e "\n${MAGENTA}>> AUR Apps (Yay)${RESET}"
    for app in "${YAY_APPS[@]}"; do
        read -p "$(echo -e "Install ${BOLD}$app${RESET}? (y/n): ")" choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            install_package "yay" "$app"
        fi
    done
    
    # Flatpak manual
    echo -e "\n${MAGENTA}>> Flatpak Apps (Flathub)${RESET}"
    for app in "${FLATPAK_APPS[@]}"; do
        read -p "$(echo -e "Install ${BOLD}$app${RESET}? (y/n): ")" choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            install_package "flatpak" "$app"
        fi
    done
    
    echo -e "\n${GREEN}${BOLD}Manual installation phase completed!${RESET}"
    read -p "Press Enter to return to menu..."
}

# Option 3: Disable Recent Tab
disable_recent() {
    echo -e "\n${CYAN}Disabling recent files tracking in GNOME...${RESET}"
    
    gsettings set org.gnome.desktop.privacy remember-recent-files false
    rm -f ~/.local/share/recently-used.xbel
    
    echo -e "${GREEN}[✔] Recent tab disabled successfully!${RESET}"
    read -p "Press Enter to return to menu..."
}

# ==============================================================================
# MAIN MENU LOOP
# ==============================================================================

while true; do
    show_banner
    
    echo -e "  ${BOLD}Please choose an option:${RESET}\n"
    echo -e "  ${CYAN}[1]${RESET} Install All Apps (Automated)"
    echo -e "  ${CYAN}[2]${RESET} Select Manually Which App to Install"
    echo -e "  ${CYAN}[3]${RESET} Disable 'Recent' Tab in File Manager"
    echo -e "  ${RED}[4]${RESET} Exit"
    echo -e "================================================================\n"
    
    read -p "Enter your choice (1-4): " user_choice
    
    case $user_choice in
        1)
            install_all
            ;;
        2)
            install_manual
            ;;
        3)
            disable_recent
            ;;
        4)
            echo -e "\n${GREEN}Thank you for using Omarcht App Installer. Goodbye!${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option. Please choose a number between 1 and 4.${RESET}"
            sleep 2
            ;;
    esac
done
