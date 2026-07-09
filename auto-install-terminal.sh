#!/bin/bash
set -e

GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null; done &

log "Installing packages..."
sudo pacman -S --noconfirm --needed fish starship eza bat ripgrep fd fzf zoxide unzip lsof

log "Installing ble.sh (bash autosuggestions)..."
if [ ! -f /usr/share/blesh/ble.sh ]; then
    git clone --depth 1 https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh
    sudo make -C /tmp/ble.sh install PREFIX=/usr
    rm -rf /tmp/ble.sh
fi

log "Configuring starship (Catppuccin transparent)..."
mkdir -p "$HOME/.config"
cat > "$HOME/.config/starship.toml" << 'STARSHIP'
add_newline = true
command_timeout = 1000

format = """\
$username\
$directory\
$git_branch\
$git_status\
$fill\
$cmd_duration\
$memory_usage\
$time\
$line_break\
$character\
"""

[character]
error_symbol = "[✗](bold #f38ba8)"
success_symbol = "[❯](bold #a6e3a1)"
vicmd_symbol = "[❮](bold #cba6f7)"

[username]
show_always = true
style_user = "fg:#cba6f7"
format = "[$user](bold #cba6f7) "

[directory]
truncation_length = 2
truncation_symbol = "…/"
style = "fg:#cdd6f4"
repo_root_style = "bold #f9e2af"
repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) "
home_symbol = ""
format = "[$path]($style) "

[git_branch]
format = "[$symbol$branch]($style) "
style = "fg:#f5c2e7"
symbol = ""

[git_status]
format = '[$all_status$ahead_behind]($style) '
style = "fg:#fab387"
conflicted = ""
up_to_date = ""
untracked = ""
modified = ""
staged = ""
renamed = "襁"
deleted = ""
stashed = ""
ahead = "↑$count"
behind = "↓$count"
diverged = "⇕↑$ahead_count↓$behind_count"

[cmd_duration]
min_time = 1000
format = "[ $duration]($style)"
style = "fg:#585b70"

[memory_usage]
disabled = false
threshold = 80
format = "[ $percentage]($style)"
style = "fg:#f38ba8"

[time]
disabled = false
format = "[󱑂 $time]($style)"
style = "fg:#89b4fa"
time_format = "%H:%M"

[fill]
symbol = " "

[os]
disabled = true

[shell]
disabled = true
STARSHIP

log "Setting up fish config..."
mkdir -p "$HOME/.config/fish/completions" "$HOME/.config/fish/functions" "$HOME/.config/fish/conf.d"

cat > "$HOME/.config/fish/config.fish" << 'FISH'
# Starship prompt
if command -q starship
    starship init fish | source
end

# Environment
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER firefox

# Aliases
if command -q eza
    alias ls "eza -lh --group-directories-first --icons=auto"
    alias lsa "ls -a"
    alias lt "eza --tree --level=2 --long --icons --git"
    alias lta "lt -a"
end

alias g git
alias v nvim
alias cat bat
alias grep rg

# Fzf
if command -q fzf
    fzf --fish | source
end

# Zoxide
if command -q zoxide
    zoxide init fish | source
end

# Abbreviations (expand on space)
abbr -a -- gco "git checkout"
abbr -a -- gst "git status"
abbr -a -- gpl "git pull"
abbr -a -- gps "git push"
abbr -a -- gcm "git commit -m"
abbr -a -- ga "git add"
abbr -a -- gaa "git add --all"
abbr -a -- glog "git log --oneline --graph --decorate -20"
abbr -a -- gc "git clone"
abbr -a -- gbr "git branch"
abbr -a -- gd "git diff"
abbr -a -- gp "git push"
abbr -a -- nv "nvim"
abbr -a -- py "python"
abbr -a -- dev "cd ~/Projects"

# Utility functions
function mkcd
    mkdir -p $argv && cd $argv
end

function extract
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.gz' '*.tgz'
                tar xzf $argv[1]
            case '*.tar.bz2' '*.tbz'
                tar xjf $argv[1]
            case '*.tar.xz'
                tar xJf $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.rar'
                unrar x $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "Unknown archive format"
        end
    else
        echo "File not found"
    end
end

function up
    set -l count 1
    if test (count $argv) -ge 1
        set count $argv[1]
    end
    set -l dots ""
    for i in (seq $count)
        set dots "$dots../"
    end
    cd $dots
end

function myip
    curl -s ifconfig.me
end

function cheat
    if test (count $argv) -ge 1
        curl -s "cheat.sh/$argv[1]"
    else
        echo "Usage: cheat <command>"
    end
end

function ports
    lsof -i -P -n | awk 'NR>1 {print $1, $3, $9}' | sort -u
end

function findfile
    fd --type f --follow --hidden $argv 2>/dev/null
end

# Greeting
set fish_greeting
FISH

cat > "$HOME/.config/fish/functions/fish_greeting.fish" << 'FISHGREET'
function fish_greeting
    fastfetch
end
FISHGREET

log "Configuring dircolors..."
dircolors -p > "$HOME/.dircolors"

log "Configuring bash fallback (.bashrc)..."
cat > "$HOME/.bashrc" << 'BASHRC'
[[ $- != *i* ]] && return

source ~/.local/share/omarchy/default/bash/rc

# dircolors
eval "$(dircolors ~/.dircolors 2>/dev/null)"

# ble.sh autosuggestions
[[ $- == *i* ]] && source /usr/share/blesh/ble.sh 2>/dev/null

# fastfetch
fastfetch
BASHRC

log "Changing default shell to fish..."
if [ "$SHELL" != "/usr/bin/fish" ]; then
    sudo chsh -s /usr/bin/fish "$USER"
fi

log "All done! Open a new terminal or run: exec fish"
