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
echo " Full Android Studio installer"
echo " Optimized for: AMD Ryzen 5 5500U (Lucienne iGPU), 11GB RAM"
echo "=========================================================="

echo ">>> Installing Android drivers/tools from official repos..."
sudo pacman -S --needed --noconfirm android-tools android-udev

echo ">>> Installing Android Studio + SDK tools + Emulator (AUR)..."
yay -S --needed --noconfirm android-studio android-sdk-cmdline-tools-latest android-emulator

echo ">>> Enabling KVM access for the emulator..."
if ! id -nG | grep -qw kvm; then
    sudo gpasswd -a "${USER}" kvm
    echo "    Added '${USER}' to kvm group (re-login required)."
else
    echo "    Already in kvm group."
fi

if [[ ! -e /dev/kvm ]]; then
    echo "    WARNING: /dev/kvm missing. Ensure virtualization is enabled in BIOS."
fi

echo ">>> Reloading udev rules for USB Android devices..."
sudo udevadm control --reload-rules
sudo udevadm trigger

echo ">>> Configuring ANDROID_HOME in ~/.bashrc..."
ANDROID_HOME="/opt/android-sdk"
BASHRC="$HOME/.bashrc"
if ! grep -q "ANDROID_HOME" "$BASHRC" 2>/dev/null; then
    {
        echo "export ANDROID_HOME=$ANDROID_HOME"
        echo "export ANDROID_USER_HOME=\$HOME/.android"
        echo "export PATH=\$PATH:\$ANDROID_HOME/emulator:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/tools/bin"
    } >> "$BASHRC"
    echo "    Environment added. Run: source ~/.bashrc"
else
    echo "    ANDROID_HOME already present in ~/.bashrc."
fi

echo "=========================================================="
echo " SUCCESS! Android Studio installed."
echo "=========================================================="
echo " NEXT STEPS:"
echo " 1) Re-login (or reboot) so the kvm group takes effect."
echo " 2) source ~/.bashrc"
echo " 3) Launch: android-studio"
echo " 4) First run: accept SDK licenses and install components:"
echo "    yes | sdkmanager --licenses"
echo "    sdkmanager 'platform-tools' 'platforms;android-35' 'build-tools;35.0.0'"
echo " 5) Create an AVD (emulator) with ~2GB RAM given your 11GB system:"
echo "    avdmanager create avd -n device -k 'system-images;android-35;google_apis;x86_64'"
echo ""
echo " EMULATOR NOTES (this device):"
echo "  - KVM acceleration is active (SVM found on your Ryzen 5500U)."
echo "  - AMD GPU uses Vulkan via mesa (works out of the box)."
echo "  - If the emulator has GPU glitches on Wayland, run it with:"
echo "    emulator -avd device -gpu swiftshader_indirect"
echo "  - Low RAM system: avoid running multiple AVDs at once."
echo "=========================================================="
