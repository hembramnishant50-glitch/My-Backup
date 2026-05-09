#!/usr/bin/env bash
# ============================================================
# OCR Snapper — Omarchy / Waybar
# Languages : English + Hindi
# ============================================================

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    _dbus="/run/user/$(id -u)/bus"
    [[ -S "$_dbus" ]] && export DBUS_SESSION_BUS_ADDRESS="unix:path=${_dbus}"
fi

# ══════════════════════════════════════════════════════════════
# CONFIG — set MY_LANGS to the languages you use daily.
# Combine with + (e.g. "eng+hin" or "eng+fra+deu")
# More languages = slightly slower. Keep it to what you need.
#
# ── SOUTH ASIA ───────────────────────────────────────────────
#   eng=English   hin=Hindi     ben=Bengali   tam=Tamil
#   tel=Telugu    mar=Marathi   guj=Gujarati  urd=Urdu
#   pan=Punjabi   mal=Malayalam kan=Kannada   sin=Sinhala
#   nep=Nepali    san=Sanskrit
#
# ── EAST ASIA ────────────────────────────────────────────────
#   chi_sim=Chinese (Simplified)    chi_tra=Chinese (Traditional)
#   jpn=Japanese    kor=Korean      vie=Vietnamese
#   tha=Thai        khm=Khmer       mya=Burmese
#
# ── MIDDLE EAST & CENTRAL ASIA ───────────────────────────────
#   ara=Arabic      fas=Persian/Farsi   heb=Hebrew
#   tur=Turkish     kaz=Kazakh          uzb=Uzbek
#
# ── EUROPE ───────────────────────────────────────────────────
#   fra=French    deu=German    spa=Spanish   por=Portuguese
#   ita=Italian   rus=Russian   pol=Polish    nld=Dutch
#   swe=Swedish   nor=Norwegian dan=Danish    fin=Finnish
#   ell=Greek     ukr=Ukrainian ces=Czech     ron=Romanian
#   hun=Hungarian hrv=Croatian  bul=Bulgarian slk=Slovak
#
# ── AFRICA ───────────────────────────────────────────────────
#   afr=Afrikaans   amh=Amharic   swa=Swahili   yor=Yoruba
#   ibo=Igbo        hau=Hausa     som=Somali    zul=Zulu
#
# ── AMERICAS ─────────────────────────────────────────────────
#   spa=Spanish   por=Portuguese   que=Quechua   hat=Haitian Creole
#
# Install any pack:
#   Arch  : sudo pacman -S tesseract-data-<code>
#   Debian: sudo apt install tesseract-ocr-<code>
# ══════════════════════════════════════════════════════════════

MY_LANGS="eng+hin"

TESSDATA_DIR="/usr/share/tessdata"

# USE_PICKER: false = always use MY_LANGS silently (fastest)
#             true  = wofi menu to pick before each snap
USE_PICKER=false

# ── helpers ──────────────────────────────────────────────────

die() {
    notify-send -u critical -i "dialog-error" "OCR Snapper" "$1" -t 4000 2>/dev/null || true
    echo "ERROR: $1" >&2
    exit 1
}

ok() {
    notify-send -i "accessories-text-editor" "OCR Snapper" "$1" -t 1500 2>/dev/null || true
}

# ── dependency check ─────────────────────────────────────────

for cmd in grim slurp tesseract wl-copy; do
    command -v "$cmd" &>/dev/null || die "Missing: $cmd"
done

# ── verify language packs are installed ──────────────────────

for lang in ${MY_LANGS//+/ }; do
    [[ -f "$TESSDATA_DIR/${lang}.traineddata" ]] \
        || die "Tessdata missing for '$lang' — run: sudo pacman -S tesseract-data-${lang}  (or apt install tesseract-ocr-${lang})"
done

# ── wofi picker (only shown when USE_PICKER=true) ────────────

LANGS="$MY_LANGS"

if [[ "$USE_PICKER" == true ]]; then
    command -v wofi &>/dev/null || die "USE_PICKER=true but wofi not installed"

    ALL_LANGS=$(find "$TESSDATA_DIR" -maxdepth 1 -name "*.traineddata" -printf '%f\n' \
        | sed 's/\.traineddata$//' | sort | paste -sd'+')

    MENU="${MY_LANGS}  ← fast (your languages)"$'\n'
    MENU+="ALL  ← slow (every installed language)"$'\n'
    while IFS= read -r lang; do
        MENU+="$lang"$'\n'
    done < <(printf '%s' "$ALL_LANGS" | tr '+' '\n')

    selected=$(printf '%s' "$MENU" | wofi \
        --dmenu \
        --prompt "OCR language" \
        --lines 12 \
        --width 420 \
        --hide-scroll \
        --no-actions \
        2>/dev/null) || exit 0

    if   [[ "$selected" == ALL* ]];           then LANGS="$ALL_LANGS"
    elif [[ "$selected" == "${MY_LANGS}"* ]]; then LANGS="$MY_LANGS"
    else LANGS="${selected%% *}"
    fi

    [[ -n "$LANGS" ]] || exit 0
fi

# ── step 1: select area ──────────────────────────────────────

area=$(slurp 2>/dev/null) || exit 0

# ── step 2: screenshot ───────────────────────────────────────

img=$(mktemp /tmp/ocr_snap_XXXXXX.png)
processed=""
trap 'rm -f "$img" "$processed"' EXIT

grim -g "$area" "$img" || die "Screenshot failed"

# ── step 3: preprocess for accuracy ──────────────────────────
#
#  -colorspace Gray      Removes colour noise; Tesseract is grayscale-only
#                        internally — doing it explicitly is cleaner.
#
#  -resize 300%          Upscales to ~300 DPI equivalent (Tesseract's sweet
#                        spot). 200% was not enough for small UI text or
#                        Hindi conjunct characters (matras, half-forms).
#
#  -level 15%,85%        Stretches contrast: pushes near-white bg to white
#                        and near-black text to black. Fixes washed-out or
#                        slightly grey screenshots. Big accuracy win.
#
#  -unsharp 0x1          Light sharpening after upscale to crisp character
#                        edges. Fast single-pass, not the slow Gaussian sharpen.

if command -v convert &>/dev/null; then
    processed=$(mktemp /tmp/ocr_proc_XXXXXX.png)
    convert "$img" \
        -colorspace Gray \
        -resize 300% \
        -level 15%,85% \
        -unsharp 0x1 \
        "$processed" 2>/dev/null && img="$processed"
fi

# ── step 4: OCR ──────────────────────────────────────────────
#
# --oem 1        LSTM neural net only — faster and more accurate than legacy.
#
# --psm 3        Fully automatic page segmentation. Much better than psm 6
#                for screen content that mixes Hindi + English, has buttons,
#                labels, or multi-column layout. psm 6 (uniform block) was
#                causing garbled output on anything that wasn't a plain paragraph.
#
# preserve_interword_spaces=1
#                Keeps natural word spacing. Without this, Hindi words get
#                merged or English words split incorrectly.
#
# load_system_dawg / load_freq_dawg — intentionally LEFT ON (default = true).
#                These word-frequency dictionaries let Tesseract correct
#                ambiguous characters ("rn" vs "m", "0" vs "O" etc).
#                Turning them off was the main reason text was coming out wrong.
#
# tessedit_do_invert — intentionally LEFT ON (default = 1) so dark-mode /
#                white-on-dark snaps are handled correctly.

text=$(tesseract "$img" stdout \
    -l "$LANGS" \
    --oem 1 \
    --psm 3 \
    -c preserve_interword_spaces=1 \
    2>/dev/null) \
    || die "OCR failed — check language packs:\n  sudo pacman -S tesseract-data-hin tesseract-data-eng"

[[ -n "${text//[[:space:]]/}" ]] || die "No text detected — try selecting a clearer region"

# ── step 5: clipboard ────────────────────────────────────────

printf '%s' "$text" | wl-copy

ok "Copied [$LANGS] — paste with Ctrl+V"