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
    printf "${MAGENTA}${BOLD}        O M A R C H Y   T E R M I N A L   S E T U P        ${NC}\n"
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
        printf "\r${CYAN}Working: ${WHITE}%-22s ${YELLOW}[${GREEN}%s${WHITE}%s${YELLOW}] ${CYAN}%3d%%${NC}" \
            "$app_name" "$bar" "$space" "$progress"
        sleep "$delay"
    done

    wait "$pid" 2>/dev/null
    local rc=$?

    full_bar=""
    for ((i=0; i<bar_length; i++)); do full_bar="${full_bar}█"; done

    if (( rc == 0 )); then
        printf "\r\e[K${GREEN}[✔] Done: ${BOLD}%-24s ${YELLOW}[${GREEN}%s${YELLOW}] ${CYAN}100%%${NC}\n" \
            "$app_name" "$full_bar"
    else
        printf "\r\e[K${RED}[✘] FAILED: ${BOLD}%-24s ${YELLOW}[${RED}%s${YELLOW}]${NC}\n" \
            "$app_name" "$bar"
    fi

    tput cnorm 2>/dev/null || true
    return $rc
}

run_bg() {
    local label=$1
    shift
    local log pid rc
    log=$(mktemp)
    ( "$@" >"$log" 2>&1 ) &
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

pm_installed() { pacman -Q "$1" &>/dev/null; }

PKGS=(
    zsh fish zsh-autosuggestions zsh-syntax-highlighting zsh-completions
    aichat fastfetch fzf zoxide eza bat git
)
PKG_NAMES=(
    "zsh" "fish" "autosuggestions" "syntax highlighting" "zsh completions"
    "aichat (AI)" "fastfetch" "fzf" "zoxide" "eza" "bat" "git"
)

install_packages() {
    printf "${MAGENTA}>> Installing terminal packages${NC}\n"
    local missing=() missing_names=()
    for i in "${!PKGS[@]}"; do
        if ! pm_installed "${PKGS[$i]}"; then
            missing+=("${PKGS[$i]}")
            missing_names+=("${PKG_NAMES[$i]}")
        else
            printf "${DIM}  %s (already installed)${NC}\n" "${PKG_NAMES[$i]}"
        fi
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        printf "${GREEN}  All packages present.${NC}\n"
        return 0
    fi
    run_bg "pacman install" sudo pacman -S --needed --noconfirm "${missing[@]}" \
        || printf "${YELLOW}  Could not install some packages. See errors above.${NC}\n"
}

ensure_ohmyzsh() {
    printf "${MAGENTA}>> Oh My Zsh${NC}\n"
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        printf "${DIM}  ~/.oh-my-zsh already present.${NC}\n"
        return 0
    fi
    run_bg "oh-my-zsh clone" git clone --depth=1 \
        https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
}

ensure_omf() {
    printf "${MAGENTA}>> Oh My Fish${NC}\n"
    if [[ ! -d "$HOME/.local/share/omf" ]]; then
        run_bg "omf clone" git clone --depth=1 \
            https://github.com/oh-my-fish/oh-my-fish.git "$HOME/.local/share/omf"
    else
        printf "${DIM}  ~/.local/share/omf already present.${NC}\n"
    fi
    mkdir -p "$HOME/.config/fish/conf.d" "$HOME/.config/omf"

    cat >"$HOME/.config/fish/conf.d/omf.fish" <<'EOF'
# Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

# Load Oh My Fish configuration.
source $OMF_PATH/init.fish
EOF

    echo "theme default" >"$HOME/.config/omf/bundle"
    echo "stable" >"$HOME/.config/omf/channel"
    echo "default" >"$HOME/.config/omf/theme"

    run_bg "omf install" fish -c 'omf install'
}

ensure_oh_my_posh() {
    printf "${MAGENTA}>> oh-my-posh${NC}\n"
    mkdir -p "$HOME/.local/bin" "$HOME/.config/oh-my-posh"
    if [[ ! -x "$HOME/.local/bin/oh-my-posh" ]]; then
        run_bg "oh-my-posh download" bash -c \
            'curl -fsSL https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v30.6.2/posh-linux-amd64 -o "$HOME/.local/bin/oh-my-posh" && chmod +x "$HOME/.local/bin/oh-my-posh"'
    else
        printf "${DIM}  binary already present.${NC}\n"
    fi
    if [[ ! -f "$HOME/.config/oh-my-posh/amro.omp.json" ]]; then
        run_bg "amro theme download" bash -c \
            'curl -fsSL https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/amro.omp.json -o "$HOME/.config/oh-my-posh/amro.omp.json"'
    else
        printf "${DIM}  amro theme already present.${NC}\n"
    fi
}

write_zshrc() {
    printf "${MAGENTA}>> Writing ~/.zshrc${NC}\n"
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
    cat >"$HOME/.zshrc" <<'EOF'
# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# ---------- Oh My Zsh ----------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="" # starship renders the prompt
plugins=(git sudo)
source "$ZSH/oh-my-zsh.sh"

# ---------- History ----------
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# ---------- Omarchy env ----------
export OMARCHY_PATH=$HOME/.local/share/omarchy
export PATH=$OMARCHY_PATH/bin:$PATH:$HOME/.local/bin
export SUDO_EDITOR="${EDITOR:-nvim}"
export BAT_THEME=ansi
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ---------- Autosuggestions + syntax highlighting ----------
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ---------- fzf ----------
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# ---------- oh-my-posh prompt ----------
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/amro.omp.json)"

# ---------- zoxide ----------
eval "$(zoxide init zsh)"
cd() {
  if (( $# == 0 )); then
    builtin cd ~ || return
  elif [[ -d $1 ]]; then
    builtin cd "$1" || return
  else
    if ! z "$@"; then
      echo "Error: Directory not found"
      return 1
    fi
    printf "\U000F17A9 "
    pwd
  fi
}

# ---------- mise ----------
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# ---------- fastfetch (once per session) ----------
if [[ ! -f "$HOME/.cache/fastfetch_done" ]]; then
  fastfetch
  mkdir -p "$HOME/.cache"
  touch "$HOME/.cache/fastfetch_done"
fi

# ---------- aichat shell assistant ----------
ai() { aichat "$@"; }

# ---------- Aliases / functions (ported from omarchy) ----------
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'

if [[ "$TERM" == "xterm-kitty" ]]; then
  ff() { fzf --preview 'case $(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'; }
else
  ff() { fzf --preview 'bat --style=numbers --color=always {}'; }
fi
alias eff='$EDITOR "$(ff)"'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias c='opencode'
alias d='docker'
alias t='tmux attach || tmux new -s Work'

n() { if [ "$#" -eq 0 ]; then command nvim .; else command nvim "$@"; fi; }

alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
gcad() { git commit -a --amend "$@"; }
EOF
    printf "${GREEN}  OK: ~/.zshrc written.${NC}\n"
}

write_fish_config() {
    printf "${MAGENTA}>> Writing fish config${NC}\n"
    mkdir -p "$HOME/.config/fish/conf.d"
    [[ -f "$HOME/.config/fish/config.fish" ]] && cp "$HOME/.config/fish/config.fish" "$HOME/.config/fish/config.fish.bak.$(date +%s)"
    cat >"$HOME/.config/fish/config.fish" <<'EOF'
# ---------- Omarchy env ----------
set -gx OMARCHY_PATH $HOME/.local/share/omarchy
set -gx PATH $OMARCHY_PATH/bin $PATH $HOME/.local/bin
set -gx BAT_THEME ansi
set -gx MANROFFOPT -c

# ---------- oh-my-posh prompt ----------
oh-my-posh init fish --config ~/.config/oh-my-posh/amro.omp.json | source

# ---------- zoxide ----------
zoxide init fish | source
function cd
    if test (count $argv) -eq 0
        builtin cd $HOME
    else if test -d $argv[1]
        builtin cd $argv[1]
    else
        __zoxide_z $argv
    end
end

# ---------- mise ----------
mise activate fish | source

# ---------- fzf (Ctrl-R history, Ctrl-T files) ----------
fzf --fish | source

# ---------- fastfetch (once per session) ----------
if not test -f $HOME/.cache/fastfetch_done
    fastfetch
    mkdir -p $HOME/.cache
    touch $HOME/.cache/fastfetch_done
end

# ---------- aichat shell assistant ----------
function ai
    aichat $argv
end

# ---------- Aliases / functions (ported from omarchy) ----------
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'

function ff
    fzf --preview 'bat --style=numbers --color=always {}'
end

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias c='opencode'
alias d='docker'
alias t='tmux attach || tmux new -s Work'

function n
    if test (count $argv) -eq 0
        command nvim .
    else
        command nvim $argv
    end
end

alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
EOF
    printf "${GREEN}  OK: fish config written.${NC}\n"
}

set_default_shell() {
    printf "${MAGENTA}>> Setting zsh as default shell${NC}\n"
    if [[ "$SHELL" == "/usr/bin/zsh" ]] || [[ "$SHELL" == "/bin/zsh" ]]; then
        printf "${DIM}  zsh is already the default.${NC}\n"
        return 0
    fi
    if chsh -s /usr/bin/zsh; then
        printf "${GREEN}  OK: default shell is now zsh (restart terminal to apply).${NC}\n"
    else
        printf "${YELLOW}  chsh failed; run manually: chsh -s /usr/bin/zsh${NC}\n"
    fi
}

write_fastfetch() {
    printf "${MAGENTA}>> Writing ~/.config/fastfetch/config.jsonc${NC}\n"
    mkdir -p "$HOME/.config/fastfetch"
    [[ -f "$HOME/.config/fastfetch/config.jsonc" ]] && cp "$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc.bak.$(date +%s)"
    cat >"$HOME/.config/fastfetch/config.jsonc" <<'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file",
    "source": "~/.config/omarchy/branding/about.txt",
    "color": { "1": "green" },
    "padding": {
      "top": 2,
      "right": 6,
      "left": 2
    }
  },
  "modules": [
    {
      "type": "title",
      "format": "{user-name}@{host-name}",
      "color": "bold cyan"
    },
    "break",
    {
      "type": "custom",
      "format": "\u001b[90m┌──────────────────────Hardware──────────────────────┐"
    },
    {
      "type": "host",
      "key": " PC",
      "keyColor": "green"
    },
    {
      "type": "cpu",
      "key": "│ ├",
      "showPeCoreCount": true,
      "keyColor": "green"
    },
    {
      "type": "gpu",
      "key": "│ ├",
      "detectionMethod": "pci",
      "keyColor": "green"
    },
    {
      "type": "display",
      "key": "│ ├󱄄",
      "keyColor": "green"
    },
    {
      "type": "disk",
      "key": "│ ├󰋊",
      "keyColor": "green"
    },
    {
      "type": "memory",
      "key": "│ ├",
      "keyColor": "green"
    },
    {
      "type": "temperature",
      "key": "│ ├󰔄",
      "keyColor": "green"
    },
    {
      "type": "swap",
      "key": "└ └󰓡 ",
      "keyColor": "green"
    },
    {
      "type": "custom",
      "format": "\u001b[90m└────────────────────────────────────────────────────┘"
    },
    "break",
    {
      "type": "custom",
      "format": "\u001b[90m┌──────────────────────Software──────────────────────┐"
    },
    {
      "type": "command",
      "key": "\ue900 OS",
      "keyColor": "blue",
      "text": "version=$(omarchy-version); echo \"Omarchy $version\""
    },
    {
      "type": "command",
      "key": "│ ├󰘬",
      "keyColor": "blue",
      "text": "branch=$(omarchy-version-branch); echo \"$branch\""
    },
    {
      "type": "command",
      "key": "│ ├󰔫",
      "keyColor": "blue",
      "text": "channel=$(omarchy-version-channel); echo \"$channel\""
    },
    {
      "type": "kernel",
      "key": "│ ├",
      "keyColor": "blue"
    },
    {
      "type": "wm",
      "key": "│ ├",
      "keyColor": "blue"
    },
    {
      "type": "de",
      "key": " DE",
      "keyColor": "blue"
    },
    {
      "type": "terminal",
      "key": "│ ├",
      "keyColor": "blue"
    },
    {
      "type": "packages",
      "key": "│ ├󰏖",
      "keyColor": "blue"
    },
    {
      "type": "wmtheme",
      "key": "│ ├󰉼",
      "keyColor": "blue"
    },
    {
      "type": "shell",
      "key": "│ ├󱘖",
      "keyColor": "blue"
    },
    {
      "type": "command",
      "key": "│ ├󰸌",
      "keyColor": "blue",
      "text": "theme=$(omarchy-theme-current); echo -e \"$theme \\e[38m●\\e[37m●\\e[36m●\\e[35m●\\e[34m●\\e[33m●\\e[32m●\\e[31m●\""
    },
    {
      "type": "terminalfont",
      "key": "└ └",
      "keyColor": "blue"
    },
    {
      "type": "custom",
      "format": "\u001b[90m└────────────────────────────────────────────────────┘"
    },
    "break",
    {
      "type": "custom",
      "format": "\u001b[90m┌────────────────Age / Uptime / Update───────────────┐"
    },
    {
      "type": "command",
      "key": "󱦟 OS Age",
      "keyColor": "magenta",
      "text": "echo $(( ($(date +%s) - $(stat -c %W /)) / 86400 )) days"
    },
    {
      "type": "uptime",
      "key": "󱫐 Uptime",
      "keyColor": "magenta"
    },
    {
      "type": "command",
      "key": " Update",
      "keyColor": "magenta",
      "text": "updated=$(omarchy-version-pkgs); echo \"$updated\""
    },
    {
      "type": "custom",
      "format": "\u001b[90m└────────────────────────────────────────────────────┘"
    },
    "break",
    {
      "type": "colors",
      "paddingLeft": 8,
      "symbol": "circle",
      "blockWidth": 2
    },
    "break"
  ]
}
EOF
    printf "${GREEN}  OK: fastfetch config written.${NC}\n"
}

aichat_hint() {
    if ! command -v aichat &>/dev/null; then return 0; fi
    if [[ -f "$HOME/.config/aichat/config.yaml" ]] || [[ -f "$HOME/.config/aichat/config.json" ]]; then
        return 0
    fi
    printf "${YELLOW}\n  First-time aichat setup: run  aichat config  to add your API key/provider.\n${NC}"
}

full_setup() {
    printf "\n${BOLD}${CYAN}--- Full terminal setup ---${NC}\n\n"
    install_packages
    ensure_ohmyzsh
    ensure_omf
    ensure_oh_my_posh
    write_zshrc
    write_fish_config
    write_fastfetch
    set_default_shell
    aichat_hint
    printf "\n${GREEN}${BOLD}Terminal setup complete! Reopen your terminal.${NC}\n"
}

main() {
    while true; do
        show_banner
        echo -e "  ${BOLD}Please choose an option:${NC}\n"
        echo -e "  ${CYAN}[1]${NC} Full Setup (packages + configs + default shell)"
        echo -e "  ${CYAN}[2]${NC} Install Packages Only"
        echo -e "  ${CYAN}[3]${NC} Write Configs Only (zsh + fish + fastfetch)"
        echo -e "  ${CYAN}[4]${NC} Set zsh as Default Shell Only"
        echo -e "  ${RED}[q]${NC} Exit"
        echo -e "================================================================\n"

        local opt
        read -rp "Enter your choice (1-4 or q): " opt
        case "${opt,,}" in
            1) full_setup ;;
            2) install_packages ;;
            3) ensure_ohmyzsh; ensure_omf; ensure_oh_my_posh; write_zshrc; write_fish_config; write_fastfetch ;;
            4) set_default_shell ;;
            q|quit) echo -e "\n${GREEN}Goodbye!${NC}\n"; exit 0 ;;
            *) echo -e "\n${RED}Invalid option.${NC}"; sleep 1 ;;
        esac
        read -rp "Press Enter to continue..."
    done
}

main "$@"
