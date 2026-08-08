#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Do not run this script as root. Run as a normal user (sudo will prompt)."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    echo "ERROR: pacman not found. This script only supports Arch Linux."
    exit 1
fi

AUR_PKGS=(base-devel git)

if ! command -v yay &>/dev/null; then
    echo ">>> yay (AUR helper) not found. Installing it first..."
    sudo pacman -S --needed --noconfirm "${AUR_PKGS[@]}"
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm && cd - >/dev/null
    rm -rf /tmp/yay-bin
else
    MISSING=()
    for pkg in "${AUR_PKGS[@]}"; do
        pacman -Q "${pkg}" &>/dev/null || MISSING+=("${pkg}")
    done
    if [[ ${#MISSING[@]} -gt 0 ]]; then
        echo ">>> Installing AUR build requirements: ${MISSING[*]}"
        sudo pacman -S --needed --noconfirm "${MISSING[@]}"
    fi
fi

echo "=========================================================="
echo " Note-taking apps installer for this device"
echo "=========================================================="
echo " 1) Obsidian    (AUR: obsidian-bin)"
echo " 2) Joplin      (AUR: joplin-bin)"
echo " 3) Notesnook   (AUR: notesnook-bin)"
echo " 4) Logseq      (AUR: logseq-desktop-bin)"
echo "----------------------------------------------------------"
echo " Enter numbers separated by commas (e.g. 1,3)"
echo " 'a' = install all, 'q' = quit"
read -rp "> " SELECTION

case "${SELECTION,,}" in
    q|quit) echo "Aborted."; exit 0 ;;
    a|all)  CHOICES=(1 2 3 4) ;;
    *)
        IFS=', ' read -r -a CHOICES <<< "${SELECTION}"
        ;;
esac

installed() { yay -Q "$1" &>/dev/null; }

install_aur() {
    local pkg="$1" name="$2"
    if installed "$pkg"; then
        echo ">>> $name is already installed. Skipping."
    else
        echo ">>> Installing $name ($pkg)..."
        yay -S --needed --noconfirm "$pkg"
    fi
}

install_obsidian()  { install_aur obsidian-bin "Obsidian"; }
install_joplin()    { install_aur joplin-bin "Joplin"; }
install_notesnook() { install_aur notesnook-bin "Notesnook"; }
install_logseq()    { install_aur logseq-desktop-bin "Logseq"; }

echo ""
for c in "${CHOICES[@]}"; do
    case "$c" in
        1) install_obsidian ;;
        2) install_joplin ;;
        3) install_notesnook ;;
        4) install_logseq ;;
        *) echo ">>> Ignoring invalid choice: $c" ;;
    esac
done

echo "=========================================================="
echo " SUCCESS! Installed app(s):"
for c in "${CHOICES[@]}"; do
    case "$c" in
        1) echo "  - Obsidian   (run: obsidian)" ;;
        2) echo "  - Joplin     (run: joplin)" ;;
        3) echo "  - Notesnook  (run: notesnook)" ;;
        4) echo "  - Logseq     (run: logseq)" ;;
    esac
done
echo " Note: Joplin syncs via its own services; Obsidian/Logseq"
echo " work on local Markdown vaults you point them at."
echo "=========================================================="
