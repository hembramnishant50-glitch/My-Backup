#!/usr/bin/env python3
import subprocess
import json
import hashlib
import random
import re

# --- CONFIGURATION ---
MAX_TITLE_LEN = 35 

# --- MUSIC FILTER ---
MUSIC_PLAYERS = ["spotify", "ncspot", "cider", "rhythmbox", "vlc", "mpv", "music"]
MUSIC_WEB_KEYWORDS = ["spotify", "soundcloud", "music", "deezer", "bandcamp"]
PATTERNS = [" ▃▆▄", " ▄▃▇", " ▆▃▅", " ▇▆▃", " ▃▅▇"]

# --- DYNAMIC BROWSER MAP ---
# If a window is one of these browsers, the script will extract the WEBSITE name 
# from the title and display that on Waybar instead of the browser name.
BROWSER_MAP = {
    "brave":             ("󰖟", "#ff542b", " - Brave"),
    "zen":               ("󰈹", "#4f4f4f", " - Zen Browser"),
    "firefox":           ("", "#ff7139", " - Mozilla Firefox"),
    "librewolf":         ("󰈹", "#3269d6", " - LibreWolf"),
    "mullvad":           ("󰇚", "#3c9519", " - Mullvad Browser"),
    "chrome":            ("", "#4285f4", " - Google Chrome"),
    "chromium":          ("", "#4285f4", " - Chromium"),
    "vivaldi":           ("", "#ef3939", " - Vivaldi"),
    "edge":              ("", "#0078d7", " - Microsoft Edge"),
    "opera":             ("", "#ff1b2d", " - Opera"),
}

# --- EXPLICIT APP RULES ---
# Standard applications and high-priority web apps (like YouTube/Gmail) that get custom icons.
APP_RULES = {
    # --- 0. High-Priority Web Apps ---
    ("mail.google.com", "google-gmail", "gmail"): ("󰊭", "#ea4335", "Gmail"),
    ("keep.google.com", "google-keep"):           ("󰟶", "#fbbc04", "Keep"),
    ("drive.google.com", "google-drive"):         ("󰝰", "#34a853", "Drive"),
    ("calendar.google.com", "google-calendar"):   ("󰸗", "#4285f4", "Calendar"),
    ("docs.google.com", "google-docs"):           ("󰈙", "#4285f4", "Docs"),
    ("sheets.google.com", "google-sheets"):       ("󰈛", "#34a853", "Sheets"),
    ("slides.google.com", "google-slides"):       ("󰈧", "#fbbc04", "Slides"),
    ("maps.google.com", "google-maps", "maps"): ("󰉙", "#34a853", "Maps"),
    ("meet.google.com", "google-meet", "zoom"):   ("󰻵", "#00897b", "Meet"),
    ("photos.google.com", "google-photos"):     ("󰄄", "#ff4500", "Photos"),
    ("youtube.com", "google-youtube", "youtube"): ("󰗃", "#ff0000", "YouTube"),
    ("notebooklm.google.com",):                   ("󰠮", "#4285f4", "NotebookLM"),
    
    ("mail.proton.me",):     ("󰇮", "#6d4aff", "Proton Mail"),
    ("calendar.proton.me",): ("󰸗", "#6d4aff", "Proton Calendar"),
    ("drive.proton.me",):    ("󰝰", "#6d4aff", "Proton Drive"),
    ("pass.proton.me",):     ("󰷖", "#6d4aff", "Proton Pass"),
    ("vpn.proton.me",):      ("󰖂", "#6d4aff", "Proton VPN"),
    ("lumo.proton.me",):     ("󱔐", "#6d4aff", "Proton Lumo"),

    # --- 1. Terminals & Dev ---
    ("ghostty",):           ("", "#cba6f7", "Ghostty"),
    ("alacritty",):         ("", "#f9e2af", "Alacritty"),
    ("kitty",):             ("", "#cba6f7", "Kitty"),
    ("terminal", "foot", "terminator"): ("", "#f9e2af", "Terminal"),
    ("code", "vscodium"):   ("󰨞", "#007acc", "VS Code"),
    ("nvim", "vim"):        ("", "#57a143", "Neovim"),
    ("github", "git"):      ("󰊤", "#ffffff", "GitHub"),
    ("gitlab",):            ("", "#fc6d26", "GitLab"),
    ("stackoverflow",):     ("", "#f48024", "StackOverflow"),
    ("docker",):            ("", "#2496ed", "Docker"),
    ("localhost",):         ("", "#00ff00", "Localhost"),
    ("flatseal",):          ("󱓷", "#3eb34f", "Flatseal"),

    # --- 2. Education, Office & Notes ---
    ("obsidian", "clamui"): ("󱓧", "#7c4dff", "Obsidian"),
    ("anki",):              ("󰮔", "#ffffff", "Anki"),
    ("zotero",):            ("󱓷", "#cc2914", "Zotero"),
    ("onlyoffice", "desktopeditors"): ("󰏆", "#ff6f21", "ONLYOFFICE"),
    ("libreoffice",):       ("󰏆", "#185abd", "LibreOffice"),
    ("xournal",):           ("󱞈", "#2980b9", "Xournal++"),
    ("pdfarranger",):       ("󰈦", "#f1c40f", "PDF Arranger"),
    ("foliate",):           ("󰂵", "#629c44", "Foliate"),
    ("kalgebra",):          ("󰪚", "#3daee9", "KAlgebra"),
    ("pinapp", "pins"):     ("󰐚", "#4caf50", "Pins"),
    ("notion",):            ("", "#000000", "Notion"),
    ("trello",):            ("", "#0079bf", "Trello"),
    ("typora",):            ("󰂺", "#b4637a", "Typora"),

    # --- 3. Social & Chat ---
    ("discord",):           ("", "#5865f2", "Discord"),
    ("telegram", "ayugram"):("", "#24a1de", "Telegram"),
    ("whatsapp",):          ("", "#25d366", "WhatsApp"),
    ("signal",):            ("󰭹", "#3a76f0", "Signal"),
    ("reddit",):            ("", "#ff4500", "Reddit"),
    ("twitter", "x.com"):   ("", "#1da1f2", "X"),
    ("facebook",):          ("", "#1877f2", "Facebook"),
    ("instagram",):         ("", "#c13584", "Instagram"),
    ("linkedin",):          ("", "#0077b5", "LinkedIn"),
    ("pinterest",):         ("", "#bd081c", "Pinterest"),
    ("tumblr",):            ("", "#35465c", "Tumblr"),
    ("tiktok",):            ("", "#ff0050", "TikTok"),

    # --- 4. Media & Design ---
    ("vlc", "celluloid", "mpv"): ("󰕼", "#ff9900", "Media Player"),
    ("spotify",):                ("", "#1db954", "Spotify"),
    ("amberol",):                ("󰎆", "#f8d210", "Amberol"),
    ("gimp",):                   ("", "#5c5543", "GIMP"),
    ("inkscape",):               ("", "#ffffff", "Inkscape"),
    ("kdenlive",):               ("", "#3daee9", "Kdenlive"),
    ("upscayl",):                ("󰭹", "#ff4500", "Upscayl"),
    ("obs",):                    ("", "#262626", "OBS Studio"),
    ("figma",):                  ("", "#f24e1e", "Figma"),
    ("canva",):                  ("", "#00c4cc", "Canva"),
    ("audacity",):               ("󰓃", "#0000eb", "Audacity"),
    ("blanket",):                ("󰖗", "#3daee9", "Blanket"),
    ("videotrimmer", "vidcutter", "losslesscut"): ("󰐊", "#c061cb", "Video Trimmer"),
    ("handbrake",):              ("󱁆", "#b71c1c", "Handbrake"),
    ("soundconverter",):         ("󰓃", "#f57c00", "SoundConverter"),
    ("mystiq",):                 ("󰕧", "#00d2ff", "MystiQ"),
    ("footage",):                ("󰿚", "#3584e4", "Footage"),
    ("stremio",):                ("󰐊", "#7b3fe4", "Stremio"),
    ("stimulator",):             ("󰅶", "#f57c00", "Stimulator"),
    ("shortwave",):              ("󰕱", "#613583", "Shortwave"),
    ("mkvtoolnix",):             ("󰔑", "#81a2be", "MKVToolNix"),

    # --- 5. Utilities & System ---
    ("bitwarden", "1password"):  ("󰞀", "#175DDC", "Passwords"),
    ("flameshot",):              ("󰄀", "#ff4081", "Flameshot"),
    ("nautilus", "dolphin", "thunar", "files"): ("", "#3daee9", "Files"),
    ("calculator",):             ("", "#4193f4", "Calculator"),
    ("system-monitor", "missioncenter"): ("󱓟", "#3584e4", "System Monitor"),
    ("warehouse", "bazaar", "cafebazaar"): ("", "#ff9500", "Store"),
    ("localsend",):              ("󰄶", "#3db2ff", "LocalSend"),
    ("eyedropper",):             ("󰈊", "#3584e4", "Eyedropper"),
    ("metadatacleaner",):        ("󰃢", "#5e5c64", "Metadata Cleaner"),
    ("morphosis",):              ("󰈹", "#3584e4", "Morphosis"),
    ("clocks",):                 ("󱎫", "#3584e4", "Clocks"),
    ("control-center",):         ("⚙️", "#9a9996", "Settings"),
    ("gnome-software",):         ("🛍️", "#3584e4", "Software"),
    ("pavucontrol",):            ("󰓃", "#67808d", "Volume Control"),
    ("bleachbit",):              ("󰃢", "#e6e6e6", "BleachBit"),
    ("timeshift",):              ("󰁯", "#ed333b", "Timeshift"),
    ("keypunch",):               ("", "#ff4081", "Keypunch"),
    ("aether",):                 ("󰑭", "#a29bfe", "Aether"),
    ("converter",):              ("󱊲", "#3584e4", "Converter"),
    ("curlew",):                 ("󰕧", "#2e7d32", "Curlew"),

    # --- 6. AI ---
    ("careerwill",):  ("🎓", "#ff9900", "Careerwill"),
    ("chatgpt",):     ("󰚩", "#74aa9c", "ChatGPT"),
    ("gemini",):      ("󰊭", "#8ab4f8", "Gemini AI"),
    ("claude",):      ("", "#d97757", "Claude AI"),
    ("bing",):        ("", "#2583c6", "Bing Chat"),
    ("perplexity",):  ("󰚩", "#2ebfab", "Perplexity"),

    # --- 7. Games ---
    ("minecraft", "prism", "multimc", "gdlauncher"): ("󰍳", "#52b12e", "Minecraft"),
    ("retroarch",):                    ("󰊴", "#3daee9", "RetroArch"),

    # --- 8. Download Managers ---
    ("abdownloadmanager",): ("󰇚", "#00aaff", "AB Download Manager"),
    ("qbittorrent",):       ("󱑢", "#3b4ba4", "qBittorrent"),
    ("transmission",):      ("󰇚", "#e63946", "Transmission"),
    ("deluge",):            ("󱑢", "#49a010", "Deluge"),
    ("aria2",):             ("󰈚", "#f1c40f", "Aria2"),
    ("motrix",):            ("󰇚", "#ff4a00", "Motrix"),
    ("xdm",):               ("󱑢", "#2c3e50", "XDM"),
    ("uget",):              ("󰈚", "#fa8e3c", "uGet"),
    ("jdownloader",):       ("󱑣", "#ff9000", "JDownloader"),
    ("persepolis",):        ("󰈚", "#34495e", "Persepolis"),
    ("fdm",):               ("󰇚", "#00aaff", "FDM"),
    ("kget",):              ("󱑢", "#3daee9", "KGet"),
    ("megabasterd",):       ("󰗽", "#d92323", "MegaBuster"),

    # --- 9. Extras ---
    ("amazon",):            ("", "#ff9900", "Amazon"),
    ("outlook",):           ("", "#0078d4", "Outlook"),
    ("hey",):               ("󰮏", "#ffcc00", "HEY Mail"),
    ("basecamp",):          ("", "#ffcc00", "Basecamp"),
}

def get_media_info():
    """Handles Music Visualizer"""
    try:
        cmd = ["playerctl", "metadata", "--format", "{{status}}|||{{playerName}}|||{{title}}|||{{artist}}"]
        output = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, timeout=1).decode().strip()
        
        if output:
            parts = output.split("|||")
            if len(parts) == 4:
                status, player_name, title, artist = parts
                player_name = player_name.lower()
                
                if status == "Playing":
                    is_music_app = any(app in player_name for app in MUSIC_PLAYERS)
                    is_music_web = any(web in title.lower() for web in MUSIC_WEB_KEYWORDS)

                    if is_music_app or is_music_web:
                        bars = random.choice(PATTERNS)
                        display_title = title if len(title) < 25 else title[:25] + "..."
                        display = f"<span color='#a6e3a1'>{bars}</span>  {display_title}"
                        tooltip = f"Now Playing: {title} by {artist} ({player_name.capitalize()})"
                        return display, tooltip
                elif status == "Paused":
                    return "<span color='#f9e2af'>󰏤 Paused</span>", "Click to Resume"
    except:
        pass
    return None, None

def get_active_window():
    try:
        output = subprocess.check_output(["hyprctl", "activewindow", "-j"], stderr=subprocess.DEVNULL).decode("utf-8")
        data = json.loads(output)
        
        raw_title = data.get("title", "")
        raw_class = data.get("class", "").lower()
        title_lower = raw_title.lower()

        def format_output(icon, color, app_name, win_title):
            if app_name == "YouTube":
                clean_title = win_title.replace(" - YouTube", "").replace("YouTube", "").strip()
                clean_title = re.sub(r'\(\d+\)', '', clean_title).strip()
                if not clean_title: clean_title = win_title 
                if len(clean_title) > MAX_TITLE_LEN:
                    clean_title = clean_title[:MAX_TITLE_LEN] + "..."
                return f"<span color='{color}'>{icon}</span>  {app_name} <span color='#788587'>|</span> <span color='#dcd6d6'>{clean_title}</span>", win_title

            return f"<span color='{color}'>{icon}</span>  {app_name}", win_title

        # 1. EXPLICIT APPS: Check high-priority APP_RULES first (e.g., Gmail, Discord)
        for patterns, (icon, color, name) in APP_RULES.items():
            if any(p in raw_class or p in title_lower for p in patterns):
                return format_output(icon, color, name, raw_title)
        
        # 2. DYNAMIC WEB APPS: If it's a browser, extract the website name from the title
        for b_key, (b_icon, b_color, b_suffix) in BROWSER_MAP.items():
            if b_key in raw_class:
                website_name = raw_title
                
                # Strip the browser suffix (e.g., " - Google Chrome")
                if website_name.endswith(b_suffix):
                    website_name = website_name[:-len(b_suffix)].strip()
                elif website_name.endswith(" - Google Chrome"): # Fallback for some PWAs
                    website_name = website_name.replace(" - Google Chrome", "").strip()
                    
                # Clean up notification badges like (1) or (99+)
                website_name = re.sub(r'\(\d+\+?\)', '', website_name).strip()
                
                # If they open an empty tab, default to a clean name
                if not website_name or website_name == "New Tab":
                    website_name = "Web Browser"
                
                # Cap the length so it doesn't break the Waybar UI
                if len(website_name) > MAX_TITLE_LEN:
                    website_name = website_name[:MAX_TITLE_LEN] + "..."

                # Return the browser's native icon, but the pure website name!
                return format_output(b_icon, b_color, website_name, raw_title)

        # 3. Desktop Check
        if not raw_class:
            return "<span color='#dcd6d6'>󱂬</span> Desktop", "Workspace"

        # 4. Fallback for unrecognized generic apps
        clean_name = raw_class.replace("org.gnome.", "").replace("org.kde.", "").replace("com.", "").replace(".desktop", "")
        if "mitchellh." in clean_name: clean_name = clean_name.replace("mitchellh.", "")
        
        clean_name = clean_name.capitalize()
        hex_color = "#" + hashlib.md5(clean_name.encode()).hexdigest()[:6]
        
        if "gnome" in raw_class: icon = ""
        elif "kde" in raw_class: icon = ""
        else: icon = ""

        return format_output(icon, hex_color, clean_name, raw_title)

    except:
        return "<span color='#dcd6d6'>󱂬</span> Desktop", "Workspace"

if __name__ == "__main__":
    media_text, media_tooltip = get_media_info()
    if media_text:
        display_text = media_text
        tooltip_text = media_tooltip
    else:
        display_text, tooltip_text = get_active_window()
    print(json.dumps({"text": display_text, "tooltip": tooltip_text}))