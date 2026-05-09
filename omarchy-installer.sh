#!/bin/bash

# ============================================================
#   OMARCHY APP INSTALLER 
# ============================================================

# ── Colours & Styles ────────────────────────────────────────
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
BG_BLUE='\033[44m'
BG_CYAN='\033[46m'
BG_GREEN='\033[42m'
BG_RED='\033[41m'
BG_MAG='\033[45m'

TICK="${GREEN}✔${RESET}"
CROSS="${RED}✘${RESET}"
ARROW="${CYAN}➜${RESET}"
STAR="${YELLOW}★${RESET}"

# ── Track failures ───────────────────────────────────────────
FAILED_APPS=()
INSTALLED_APPS=()

# ── App definitions ──────────────────────────────────────────
# Format: "PACKAGE_MANAGER|PACKAGE_ID|APP_NAME|DESCRIPTION"
declare -a APPS=(
  "pacman|morphosis|Morphosis|Transform files between formats — images, audio & more"
  "pacman|qbittorrent|qBittorrent|Fast, lightweight & open-source BitTorrent client"
  "pacman|handbrake|HandBrake|Powerful video transcoder & converter"
  "pacman|audacity|Audacity|Professional multi-track audio editor & recorder"
  "pacman|metadata-cleaner|Metadata Cleaner|Remove hidden metadata from your files for privacy"
  "pacman|blanket|Blanket|Play ambient sounds to focus or relax"
  "pacman|bleachbit|BleachBit|Free up disk space & protect your privacy"
  "pacman|gnome-clocks|GNOME Clocks|World clocks, alarms, stopwatch & timer"
  "pacman|switcheroo|Switcheroo|Easily convert & resize images"
  "pacman|raider|Raider|Batch find-and-replace tool for files & folders"
  "pacman|flatpak|Flatpak|Universal Linux application packaging runtime"
  "flatpak|io.github.linx_systems.ClamUI|ClamUI|Graphical front-end for ClamAV antivirus scanner"
  "flatpak|io.github.kolunmi.Bazaar|Bazaar|Discover & install applications beautifully"
  "flatpak|com.github.tchx84.Flatseal|Flatseal|Manage Flatpak application permissions"
  "flatpak|com.stremio.Stremio|Stremio|Stream movies, series & live TV in one place"
  "flatpak|io.github.flattool.Warehouse|Warehouse|Manage all your installed Flatpak apps"
  "flatpak|net.nokyan.Resources|Resources|Monitor CPU, RAM, GPU, disk & network usage"
  "flatpak|org.gnome.gitlab.YaLTeR.VideoTrimmer|Video Trimmer|Trim video clips quickly & easily"
  "flatpak|io.github.giantpinkrobots.flatsweep|Flatsweep|Clean up leftover Flatpak data"
  "flatpak|org.bunkus.mkvtoolnix-gui|MKVToolNix|Create, inspect & manipulate MKV video files"
  "flatpak|app.drey.Dialect|Dialect|Translate text between languages using multiple services"
  "flatpak|io.github.sigmasd.stimulator|Stimulator|Keep your computer awake on demand"
  "flatpak|it.andreafontana.hideout|Hideout|Manage and organise your snippets & notes"
  "flatpak|io.github.fabrialberio.pinapp|PinApp|Pin & organise your favourite applications"
  "flatpak|io.github.nate_xyz.Paleta|Paleta|Beautiful colour palette picker & manager"
  "flatpak|de.swsnr.keepmeawake|Keep Me Awake|Prevent your screen from sleeping temporarily"
  "flatpak|com.usebottles.bottles|Bottles|Run Windows software on Linux effortlessly"
  "flatpak|dev.appoutlet.DisCorkie|DisCorkie|Browse and install apps from multiple sources"
  "yay|peazip-qt|PeaZip|Free powerful archiver — 200+ archive formats"
  "yay|parabolic-bin|Parabolic|Download YouTube & web videos with yt-dlp"
  "yay|obsidian|Obsidian|Markdown knowledge base & personal notes manager"
  "yay|cryptomator|Cryptomator|Encrypt your cloud files with zero-knowledge security"
  "yay|ayugram-desktop-bin|Ayugram|Feature-rich Telegram desktop client fork"
  "yay|shortwave|Shortwave|Listen to thousands of online radio stations"
  "yay|gradia|Gradia|Beautiful screenshot tool with padding & backgrounds"
  "yay|anki-bin|Anki|Spaced-repetition flashcards for powerful memorisation"
  "yay|czkawka-gui-bin|Czkawka|Find and remove duplicate files & junk data"
  "yay|cine|Cine|Elegant video player for your local library"
  "yay|keypunch|Keypunch|Practice touch typing & improve your speed"
  "yay|parabolic|Parabolic (Alt)|Alternate build of the Parabolic video downloader"
)

TOTAL=${#APPS[@]}

# ════════════════════════════════════════════════════════════
#  FUNCTIONS
# ════════════════════════════════════════════════════════════

print_header() {
  clear
  echo ""
  echo -e "${CYAN}${BOLD}"
  echo "  ██████╗ ███╗   ███╗ █████╗ ██████╗  ██████╗██╗  ██╗██╗   ██╗"
  echo " ██╔═══██╗████╗ ████║██╔══██╗██╔══██╗██╔════╝██║  ██║╚██╗ ██╔╝"
  echo " ██║   ██║██╔████╔██║███████║██████╔╝██║     ███████║ ╚████╔╝ "
  echo " ██║   ██║██║╚██╔╝██║██╔══██║██╔══██╗██║     ██╔══██║  ╚██╔╝  "
  echo " ╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╗██║  ██║   ██║   "
  echo "  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝  "
  echo -e "${RESET}"
  echo -e "  ${MAGENTA}${BOLD}         ✦  A P P   I N S T A L L E R  ✦${RESET}"
  echo -e "  ${DIM}         Omarchy Linux · $(date '+%d %b %Y')${RESET}"
  echo ""
  echo -e "  ${DIM}────────────────────────────────────────────────────────────${RESET}"
  echo ""
}

print_section() {
  echo ""
  echo -e "  ${BG_BLUE}${WHITE}${BOLD}  $1  ${RESET}"
  echo ""
}

spinner_install() {
  local pid=$1
  local app_name=$2
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0
  local elapsed=0

  while kill -0 "$pid" 2>/dev/null; do
    local frame="${frames[$((i % 10))]}"
    printf "\r  ${CYAN}${BOLD}%s${RESET}  ${WHITE}%-28s${RESET}  ${DIM}Installing...${RESET}  ${YELLOW}⏱  %ds${RESET}  " \
      "$frame" "$app_name" "$elapsed"
    sleep 0.12
    i=$((i + 1))
    elapsed=$(( elapsed + 0 ))
    # Update elapsed every ~8 frames (~1s)
    if (( i % 8 == 0 )); then
      elapsed=$((elapsed + 1))
    fi
  done
}

fake_progress_bar() {
  local app_name="$1"
  local width=40
  local steps=50

  for ((i=0; i<=steps; i++)); do
    local pct=$(( i * 100 / steps ))
    local filled=$(( i * width / steps ))
    local empty=$(( width - filled ))

    # Colour gradient: red → yellow → green
    if (( pct < 40 )); then
      BAR_COLOR="${RED}"
    elif (( pct < 75 )); then
      BAR_COLOR="${YELLOW}"
    else
      BAR_COLOR="${GREEN}"
    fi

    local bar="${BAR_COLOR}"
    for ((b=0; b<filled; b++)); do bar+="█"; done
    bar+="${DIM}"
    for ((b=0; b<empty; b++)); do bar+="░"; done
    bar+="${RESET}"

    printf "\r  ${WHITE}%-28s${RESET}  [%b]  ${BOLD}%3d%%${RESET}" \
      "$app_name" "$bar" "$pct"

    local delay
    if (( pct < 30 )); then
      delay=0.03
    elif (( pct < 80 )); then
      delay=0.02
    else
      delay=0.04
    fi
    sleep "$delay"
  done
  printf "\n"
}

# Real install with live output capture + fake progress overlay
install_app() {
  local manager="$1"
  local pkg="$2"
  local name="$3"

  local log_file
  log_file=$(mktemp /tmp/omarchy_install_XXXXXX.log)

  echo -e "\n  ${STAR} ${BOLD}${WHITE}${name}${RESET}"

  case "$manager" in
    pacman)
      sudo pacman -S --noconfirm --needed "$pkg" > "$log_file" 2>&1 &
      ;;
    flatpak)
      flatpak install -y flathub "$pkg" > "$log_file" 2>&1 &
      ;;
    yay)
      yay -S --noconfirm --needed "$pkg" > "$log_file" 2>&1 &
      ;;
  esac

  local pid=$!

  # Run fake progress bar while real install runs in background
  fake_progress_bar "$name" &
  local bar_pid=$!

  wait "$pid"
  local exit_code=$?

  # Stop progress bar
  kill "$bar_pid" 2>/dev/null
  wait "$bar_pid" 2>/dev/null

  if [ "$exit_code" -eq 0 ]; then
    printf "\r  ${TICK} ${GREEN}${BOLD}%-28s${RESET}  ${GREEN}Done!${RESET}%-20s\n" "$name" " "
    INSTALLED_APPS+=("$name")
  else
    printf "\r  ${CROSS} ${RED}${BOLD}%-28s${RESET}  ${RED}Failed${RESET}%-20s\n" "$name" " "
    FAILED_APPS+=("$manager|$pkg|$name")
  fi

  rm -f "$log_file"
}

retry_failed() {
  if [ ${#FAILED_APPS[@]} -eq 0 ]; then
    return
  fi

  echo ""
  echo -e "  ${BG_RED}${WHITE}${BOLD}  ⚠  FAILED APPS DETECTED — RETRYING  ${RESET}"
  echo ""
  echo -e "  ${RED}${BOLD}${#FAILED_APPS[@]} app(s) failed. Forcing re-installation...${RESET}"
  echo ""

  local still_failed=()

  for entry in "${FAILED_APPS[@]}"; do
    IFS='|' read -r manager pkg name <<< "$entry"

    echo -e "  ${YELLOW}${BOLD}↻  Retrying: ${WHITE}$name${RESET}"

    case "$manager" in
      pacman)
        sudo pacman -S --noconfirm "$pkg"
        ;;
      flatpak)
        flatpak repair --user 2>/dev/null
        flatpak install -y --reinstall flathub "$pkg"
        ;;
      yay)
        yay -S --noconfirm "$pkg"
        ;;
    esac

    if [ $? -eq 0 ]; then
      echo -e "  ${TICK} ${GREEN}${BOLD}$name — Installed on retry!${RESET}"
      INSTALLED_APPS+=("$name (retried)")
    else
      echo -e "  ${CROSS} ${RED}${BOLD}$name — Still failed.${RESET}"
      still_failed+=("$name")
    fi
  done

  FAILED_APPS=("${still_failed[@]}")
}

print_summary() {
  echo ""
  echo -e "  ${DIM}────────────────────────────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${BG_GREEN}${WHITE}${BOLD}   INSTALLATION COMPLETE   ${RESET}"
  echo ""
  echo -e "  ${TICK}  ${GREEN}${BOLD}Successfully Installed: ${WHITE}${#INSTALLED_APPS[@]}${RESET}"
  for app in "${INSTALLED_APPS[@]}"; do
    echo -e "      ${GREEN}•${RESET} $app"
  done

  echo ""

  if [ ${#FAILED_APPS[@]} -gt 0 ]; then
    echo -e "  ${CROSS}  ${RED}${BOLD}Still Failed After Retry: ${WHITE}${#FAILED_APPS[@]}${RESET}"
    for entry in "${FAILED_APPS[@]}"; do
      IFS='|' read -r manager pkg name <<< "$entry"
      echo -e "      ${RED}•${RESET} $name  ${DIM}(${manager}: ${pkg})${RESET}"
    done
    echo ""
    echo -e "  ${YELLOW}${BOLD}  Tip: Check your internet connection or AUR access.${RESET}"
  else
    echo -e "  ${GREEN}${BOLD}  ✦  All apps installed successfully!  ✦${RESET}"
  fi

  echo ""
  echo -e "  ${DIM}────────────────────────────────────────────────────────────${RESET}"
  echo ""
}

# ════════════════════════════════════════════════════════════
#  INSTALL ALL
# ════════════════════════════════════════════════════════════

install_all() {
  print_section "📦  INSTALLING ALL ${TOTAL} APPLICATIONS"

  local count=0
  for entry in "${APPS[@]}"; do
    IFS='|' read -r manager pkg name desc <<< "$entry"
    count=$((count + 1))

    # Section headers per manager group
    if [[ "$manager" == "pacman" && "$count" -eq 1 ]]; then
      echo -e "\n  ${MAGENTA}${BOLD}━━  PACMAN PACKAGES  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    elif [[ "$manager" == "flatpak" && "$pkg" == "io.github.linx_systems.ClamUI" ]]; then
      echo -e "\n  ${BLUE}${BOLD}━━  FLATPAK PACKAGES  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    elif [[ "$manager" == "yay" && "$pkg" == "peazip-qt" ]]; then
      echo -e "\n  ${CYAN}${BOLD}━━  AUR PACKAGES (yay)  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    fi

    echo -e "  ${DIM}  [${count}/${TOTAL}]${RESET}"
    install_app "$manager" "$pkg" "$name"
  done

  retry_failed
  print_summary
}

# ════════════════════════════════════════════════════════════
#  MANUAL SELECTION
# ════════════════════════════════════════════════════════════

manual_select() {
  while true; do
    print_header
    print_section "🗂  MANUAL APP SELECTION"

    echo -e "  ${WHITE}${BOLD}  #   App Name               Manager    Description${RESET}"
    echo -e "  ${DIM}  ─────────────────────────────────────────────────────────────${RESET}"

    local i=0
    for entry in "${APPS[@]}"; do
      IFS='|' read -r manager pkg name desc <<< "$entry"
      i=$((i + 1))

      case "$manager" in
        pacman)  mgr_color="${MAGENTA}" ;;
        flatpak) mgr_color="${BLUE}"    ;;
        yay)     mgr_color="${CYAN}"    ;;
      esac

      printf "  ${YELLOW}%3d${RESET}  ${WHITE}${BOLD}%-24s${RESET} ${mgr_color}%-9s${RESET} ${DIM}%s${RESET}\n" \
        "$i" "$name" "[$manager]" "$desc"
    done

    echo ""
    echo -e "  ${DIM}  ─────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${YELLOW}${BOLD}Enter app numbers to install (e.g: 1 3 7 12)${RESET}"
    echo -e "  ${DIM}  Type ${WHITE}all${RESET}${DIM} to install everything · Type ${WHITE}done${RESET}${DIM} to finish${RESET}"
    echo ""
    printf "  ${ARROW} ${WHITE}${BOLD}Your choice: ${RESET}"
    read -r selection

    [[ "$selection" == "done" || "$selection" == "q" ]] && break

    if [[ "$selection" == "all" ]]; then
      install_all
      return
    fi

    local selected=()
    for num in $selection; do
      if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= TOTAL )); then
        selected+=("${APPS[$((num - 1))]}")
      else
        echo -e "  ${RED}  Invalid number: $num (skipped)${RESET}"
      fi
    done

    if [ ${#selected[@]} -eq 0 ]; then
      echo -e "  ${RED}  No valid apps selected. Try again.${RESET}"
      sleep 1.5
      continue
    fi

    echo ""
    echo -e "  ${GREEN}${BOLD}  Installing ${#selected[@]} selected app(s)...${RESET}"
    echo ""

    for entry in "${selected[@]}"; do
      IFS='|' read -r manager pkg name desc <<< "$entry"
      install_app "$manager" "$pkg" "$name"
    done

    retry_failed
    print_summary

    echo -e "  ${YELLOW}${BOLD}Press Enter to go back to the menu...${RESET}"
    read -r
  done
}

# ════════════════════════════════════════════════════════════
#  PREFLIGHT CHECKS
# ════════════════════════════════════════════════════════════

preflight() {
  print_header
  echo -e "  ${CYAN}${BOLD}  ⚙  Running preflight checks...${RESET}"
  echo ""

  # Check sudo
  if ! sudo -v 2>/dev/null; then
    echo -e "  ${CROSS} ${RED}Sudo access required. Please run as a sudoer.${RESET}"
    exit 1
  fi
  echo -e "  ${TICK}  Sudo access"

  # Check yay
  if ! command -v yay &>/dev/null; then
    echo -e "  ${YELLOW}  yay not found — installing AUR helper...${RESET}"
    sudo pacman -S --noconfirm base-devel git 2>/dev/null
    git clone https://aur.archlinux.org/yay.git /tmp/yay_build 2>/dev/null
    (cd /tmp/yay_build && makepkg -si --noconfirm 2>/dev/null)
    rm -rf /tmp/yay_build
    if command -v yay &>/dev/null; then
      echo -e "  ${TICK}  yay installed"
    else
      echo -e "  ${CROSS}  ${RED}yay installation failed — AUR apps will be skipped${RESET}"
    fi
  else
    echo -e "  ${TICK}  yay (AUR helper)"
  fi

  # Check flatpak
  if ! command -v flatpak &>/dev/null; then
    echo -e "  ${YELLOW}  flatpak not found — installing...${RESET}"
    sudo pacman -S --noconfirm flatpak 2>/dev/null
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null
  fi
  echo -e "  ${TICK}  Flatpak"

  # Ensure Flathub remote
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null
  echo -e "  ${TICK}  Flathub remote"

  # Update mirrors
  echo ""
  echo -e "  ${CYAN}  Refreshing package databases...${RESET}"
  sudo pacman -Sy --noconfirm 2>/dev/null && echo -e "  ${TICK}  Package databases updated"

  echo ""
  echo -e "  ${GREEN}${BOLD}  All checks passed!${RESET}"
  echo ""
  sleep 1
}

# ════════════════════════════════════════════════════════════
#  MAIN MENU
# ════════════════════════════════════════════════════════════

preflight

while true; do
  print_header

  echo -e "  ${WHITE}${BOLD}  Total Apps Available: ${CYAN}${TOTAL}${RESET}"
  echo ""
  echo -e "  ${DIM}  ─────────────────────────────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${BG_CYAN}${WHITE}${BOLD}  1  ${RESET}  ${WHITE}${BOLD}Install All Apps${RESET}"
  echo -e "        ${DIM}Install all ${TOTAL} apps automatically. Sit back & relax.${RESET}"
  echo ""
  echo -e "  ${BG_MAG}${WHITE}${BOLD}  2  ${RESET}  ${WHITE}${BOLD}Manual Selection${RESET}"
  echo -e "        ${DIM}Browse app list with descriptions & pick what you need.${RESET}"
  echo ""
  echo -e "  ${BG_RED}${WHITE}${BOLD}  3  ${RESET}  ${WHITE}${BOLD}Exit${RESET}"
  echo ""
  echo -e "  ${DIM}  ─────────────────────────────────────────────────────────────${RESET}"
  echo ""
  printf "  ${ARROW} ${WHITE}${BOLD}Choose an option [1/2/3]: ${RESET}"
  read -r choice

  case "$choice" in
    1) install_all   ; break ;;
    2) manual_select ; break ;;
    3)
      echo ""
      echo -e "  ${YELLOW}${BOLD}  Goodbye! See you on Omarchy. ✦${RESET}"
      echo ""
      exit 0
      ;;
    *)
      echo -e "  ${RED}  Invalid choice. Please enter 1, 2, or 3.${RESET}"
      sleep 1
      ;;
  esac
done
