#!/bin/bash

# --- CONFIGURATION ---
CITY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/scripts/weather_city.txt"

# Read the city from the file, or default to Purnia if the file doesn't exist yet
if [ -f "$CITY_FILE" ]; then
    CITY=$(cat "$CITY_FILE")
else
    CITY="Purnia"
fi

UNITS="m" # "m" for Metric, "u" for US/Imperial
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/weather_module"
CACHE_FILE_WTTR="$CACHE_DIR/wttr.json"
CACHE_FILE_AQI="$CACHE_DIR/aqi.json"
CACHE_AGE=900 # 15 minutes (900 seconds)
# ---------------------

mkdir -p "$CACHE_DIR"
CITY_ENCODED=$(echo "$CITY" | sed 's/ /%20/g')

WEATHER_CODES='{"113":"☀️","116":"⛅","119":"☁️","122":"☁️","143":"🌫","176":"🌦","179":"🌧","182":"🌧","185":"🌧","200":"⛈","227":"🌨","230":"❄️","248":"🌫","260":"🌫","263":"🌦","266":"🌦","281":"🌧","284":"🌧","293":"🌦","296":"🌦","299":"🌧","302":"🌧","305":"🌧","308":"🌧","311":"🌧","314":"🌧","317":"🌧","320":"🌨","323":"🌨","326":"🌨","329":"❄️","332":"❄️","335":"❄️","338":"❄️","350":"🌧","353":"🌦","356":"🌧","359":"🌧","362":"🌧","365":"🌧","368":"🌨","371":"❄️","374":"🌧","377":"🌧","386":"⛈","389":"🌩","392":"⛈","395":"❄️"}'

# --- HELPER FUNCTIONS ---
get_progress_bar() {
    local percent=$1
    local length=10
    local filled=$(( percent * length / 100 ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="■"; done
    for ((i=filled; i<length; i++)); do bar+="□"; done
    echo "$bar"
}

get_uv_desc() {
    local uv=${1%.*} 
    if ! [[ "$uv" =~ ^[0-9]+$ ]]; then echo "Unknown";
    elif [ "$uv" -le 2 ]; then echo "Low"; 
    elif [ "$uv" -le 5 ]; then echo "Mod"; 
    elif [ "$uv" -le 7 ]; then echo "High"; 
    else echo "V.High"; fi
}

get_aqi_label() {
    local aqi=$1
    if ! [[ "$aqi" =~ ^[0-9]+$ ]]; then echo "Unknown";
    elif [ "$aqi" -le 50 ]; then echo "<span color='#a6e3a1'>Good</span>";
    elif [ "$aqi" -le 100 ]; then echo "<span color='#f9e2af'>Moderate</span>";
    elif [ "$aqi" -le 150 ]; then echo "<span color='#fab387'>Unhealthy (S)</span>";
    elif [ "$aqi" -le 200 ]; then echo "<span color='#eba0ac'>Unhealthy</span>";
    elif [ "$aqi" -le 300 ]; then echo "<span color='#cba6f7'>Very Unhealthy</span>";
    else echo "<span color='#f38ba8'>Hazardous</span>"; fi
}

get_css_class() {
    local code=$1
    if [[ "$code" =~ ^(113)$ ]]; then echo "clear";
    elif [[ "$code" =~ ^(116|119|122)$ ]]; then echo "cloudy";
    elif [[ "$code" =~ ^(143|248|260)$ ]]; then echo "fog";
    elif [[ "$code" =~ ^(176|263|266|293|296|299|302|305|308|311|314|317|350|353|356|359|362|365)$ ]]; then echo "rain";
    elif [[ "$code" =~ ^(179|182|185|227|230|320|323|326|329|332|335|338|368|371|374|377|395)$ ]]; then echo "snow";
    elif [[ "$code" =~ ^(200|386|389|392)$ ]]; then echo "storm";
    else echo "default"; fi
}

# --- DATA FETCHING (WITH CACHING) ---
CURRENT_TIME=$(date +%s)

# Fetch Weather
if [ -f "$CACHE_FILE_WTTR" ] && [ $((CURRENT_TIME - $(stat -c %Y "$CACHE_FILE_WTTR" 2>/dev/null || echo 0))) -lt $CACHE_AGE ]; then
    RESPONSE=$(cat "$CACHE_FILE_WTTR")
else
    RESPONSE=$(curl --max-time 5 -s "https://wttr.in/${CITY_ENCODED}?format=j1&${UNITS}")
    [ -n "$RESPONSE" ] && echo "$RESPONSE" > "$CACHE_FILE_WTTR"
fi

# Fetch AQI
if [ -f "$CACHE_FILE_AQI" ] && [ $((CURRENT_TIME - $(stat -c %Y "$CACHE_FILE_AQI" 2>/dev/null || echo 0))) -lt $CACHE_AGE ]; then
    AQI_DATA=$(cat "$CACHE_FILE_AQI")
else
    AQI_DATA=$(curl --max-time 5 -s "https://api.waqi.info/feed/${CITY_ENCODED}/?token=demo")
    [ -n "$AQI_DATA" ] && echo "$AQI_DATA" > "$CACHE_FILE_AQI"
fi

AQI_VAL=$(echo "$AQI_DATA" | jq -r '.data.aqi // "N/A"')

if [ -z "$RESPONSE" ] || [ "$(echo "$RESPONSE" | jq -r 'type')" != "object" ]; then
    jq -n -c '{"text": "󰖐 ", "tooltip": "Error: Weather Data Unavailable", "class": "error"}'
    exit 1
fi

# --- DATA PARSING ---
TEMP=$(echo "$RESPONSE" | jq -r '.current_condition[0].temp_C')
FEELS=$(echo "$RESPONSE" | jq -r '.current_condition[0].FeelsLikeC')
DESC=$(echo "$RESPONSE" | jq -r '.current_condition[0].weatherDesc[0].value')
CODE=$(echo "$RESPONSE" | jq -r '.current_condition[0].weatherCode')
HUMIDITY=$(echo "$RESPONSE" | jq -r '.current_condition[0].humidity')
UV=$(echo "$RESPONSE" | jq -r '.current_condition[0].uvIndex')
CITY_NAME=$(echo "$RESPONSE" | jq -r '.nearest_area[0].areaName[0].value | ascii_upcase')
COUNTRY=$(echo "$RESPONSE" | jq -r '.nearest_area[0].country[0].value | ascii_upcase')

ICON=$(echo "$WEATHER_CODES" | jq -r --arg code "$CODE" '.[$code] // "✨"')
CSS_CLASS=$(get_css_class "$CODE")

# --- TOOLTIP ASSEMBLY ---
TT="<b><span color='#cba6f7'>╔════════ METEOROLOGICAL DATA ════════╗</span></b>
<b><span color='#89b4fa'>║ LOCATION</span></b>   <span color='#dcd6d6'>$CITY_NAME, $COUNTRY</span>
<b><span color='#a6e3a1'>║ STATUS</span></b>     <span color='#dcd6d6'>$DESC</span>
<b><span color='#fab387'>║ TEMP</span></b>       <span color='#dcd6d6'>${TEMP}°C</span> <span color='#dcd6d6'>(Feels: ${FEELS}°C)</span>
<b><span color='#89b4fa'>║ HUMIDITY</span></b>   <span color='#dcd6d6'>[$(get_progress_bar "$HUMIDITY")]</span> <span color='#dcd6d6'>$HUMIDITY%</span>
<b><span color='#f38ba8'>║ UV INDEX</span></b>   <span color='#dcd6d6'>$UV ($(get_uv_desc "$UV"))</span>
<b><span color='#94e2d5'>║ AIR QLTY</span></b>   <span color='#dcd6d6'>$AQI_VAL ($(get_aqi_label "$AQI_VAL"))</span>
<b><span color='#cba6f7'>╠═════════════════════════════════════╣</span></b>
<b><span color='#f9e2af'>║ 12-HOUR TRAJECTORY                  ║</span></b>"

# --- DYNAMIC HOURLY CALCULATION ---
# Get current hour (00-23) and strip leading zero to prevent octal math errors
CURRENT_HOUR=$(date +%H)
CURRENT_IDX=$(( 10#$CURRENT_HOUR / 3 ))

HOURLY=""
for i in {1..4}; do
    # Calculate global 3-hour block index (0-7 is today, 8-15 is tomorrow)
    G=$(( CURRENT_IDX + i ))
    DAY_IDX=$(( G / 8 ))
    HOUR_IDX=$(( G % 8 ))
    
    # Extract the correct block directly using jq
    BLOCK=$(echo "$RESPONSE" | jq -c ".weather[$DAY_IDX].hourly[$HOUR_IDX]")
    HOURLY+="$BLOCK"$'\n'
done

while read -r hour; do
    [ "$hour" = "null" ] || [ -z "$hour" ] && continue
    
    TIME_RAW=$(echo "$hour" | jq -r '.time // "0"')
    H_TEMP=$(echo "$hour" | jq -r '.tempC')
    H_CODE=$(echo "$hour" | jq -r '.weatherCode')
    H_RAIN=$(echo "$hour" | jq -r '.chanceofrain')
    H_ICON=$(echo "$WEATHER_CODES" | jq -r --arg code "$H_CODE" '.[$code] // "✨"')
    
    TIME_RAW=$((10#$TIME_RAW))
    H_INT=$(( TIME_RAW / 100 ))
    
    if [ "$H_INT" -eq 0 ]; then H_TIME="12 AM"
    elif [ "$H_INT" -lt 12 ]; then H_TIME="${H_INT} AM"
    elif [ "$H_INT" -eq 12 ]; then H_TIME="12 PM"
    else H_TIME="$((H_INT-12)) PM"; fi

    TT+="
<b><span color='#cba6f7'>║</span></b> <span color='#dcd6d6'>$(printf "%-6s" "$H_TIME")</span> $H_ICON <span color='#f5c2e7'>$(printf "%-4s" "${H_TEMP}°C")</span> <span color='#f5c2e7'>󰖗 $(printf "%3s" "$H_RAIN")%</span>"
done <<< "$HOURLY"

TT+="
<b><span color='#cba6f7'>╠═════════════════════════════════════╣</span></b>
<b><span color='#94e2d5'>║ NEXT 2-DAY PROJECTION               ║</span></b>"

FORECAST=$(echo "$RESPONSE" | jq -c '.weather[1,2]')
while read -r day; do
    [ "$day" = "null" ] || [ -z "$day" ] && continue
    
    DATE=$(echo "$day" | jq -r '.date')
    MAX=$(echo "$day" | jq -r '.maxtempC')
    MIN=$(echo "$day" | jq -r '.mintempC')
    F_CODE=$(echo "$day" | jq -r '.hourly[4].weatherCode')
    F_ICON=$(echo "$WEATHER_CODES" | jq -r --arg code "$F_CODE" '.[$code] // "✨"')
    
    DAY_NAME=$(date -d "$DATE" '+%a' 2>/dev/null || date -j -f "%Y-%m-%d" "$DATE" "+%a" 2>/dev/null || echo "$DATE")
    
    TT+="
<b><span color='#cba6f7'>║</span></b> <span color='#dcd6d6'>$(printf "%-4s" "$DAY_NAME")</span> $F_ICON  <span color='#fab387'>$MAX°C</span> <span color='#45475a'>/</span> <span color='#89b4fa'>$MIN°C</span>"
done <<< "$FORECAST"

TT+="
<b><span color='#cba6f7'>╚═════════════════════════════════════╝</span></b>"

jq -n -c --arg text "$ICON ${TEMP}°C" --arg tooltip "$TT" --arg class "$CSS_CLASS" '{text: $text, tooltip: $tooltip, class: $class}'