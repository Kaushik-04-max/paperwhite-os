#!/bin/sh
export DISPLAY=:0
OUT="/var/local/mesquite/com.paperwhite.os/device_data.js"
OUT2="/var/local/mesquite/browser/device_data.js"
OUT3="/var/local/mesquite/store/device_data.js"
OUT4="/mnt/us/apps/com.paperwhite.os/device_data.js"

# Auto-sync latest Paperwhite OS UI & kterm launcher whenever scan_books.sh runs (on wake or boot!)
if [ -f /mnt/us/paperwhite-os/waf/index.html ]; then
    if ! cmp -s /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/com.paperwhite.os/index.html 2>/dev/null; then
        cp -rf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/com.paperwhite.os/index.html 2>/dev/null
        cp -rf /mnt/us/paperwhite-os/waf/config.xml /var/local/mesquite/com.paperwhite.os/config.xml 2>/dev/null
        cp -rf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/browser/index.html 2>/dev/null
        cp -rf /mnt/us/paperwhite-os/waf/browser_config.xml /var/local/mesquite/browser/config.xml 2>/dev/null
        cp -rf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/store/index.html 2>/dev/null
        cp -rf /mnt/us/paperwhite-os/waf/store_config.xml /var/local/mesquite/store/config.xml 2>/dev/null
        chmod +x /mnt/us/paperwhite-os/launch_kterm.sh 2>/dev/null
        sqlite3 /var/local/appreg.db "INSERT OR IGNORE INTO handlerIds(handlerId) VALUES('com.paperwhite.kterm'); INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.paperwhite.kterm','lipcId','com.paperwhite.kterm'); INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.paperwhite.kterm','command','/bin/sh /mnt/us/paperwhite-os/launch_kterm.sh'); INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.paperwhite.kterm','supportedOrientation','U');" 2>/dev/null
        NEEDS_UI_RELOAD=1
    fi
fi

# 1. Read exact live battery % from powerd battLevel, gasgauge-info -s, and wario_battery0 sysfs
BAT=$(lipc-get-prop com.lab126.powerd battLevel 2>/dev/null | head -n 1 | tr -dc '0-9')
if [ -z "$BAT" ] || [ "$BAT" -gt 100 ] 2>/dev/null; then
    BAT=$(gasgauge-info -s 2>/dev/null | head -n 1 | tr -dc '0-9')
fi
if [ -z "$BAT" ] || [ "$BAT" -gt 100 ] 2>/dev/null; then
    for sys_bat in \
        /sys/devices/system/wario_battery/wario_battery0/battery_capacity \
        /sys/class/power_supply/max77696-battery/capacity \
        /sys/class/power_supply/battery/capacity; do
        if [ -r "$sys_bat" ]; then
            BAT=$(head -n 1 "$sys_bat" 2>/dev/null | tr -dc '0-9')
            [ -n "$BAT" ] && [ "$BAT" -le 100 ] 2>/dev/null && break
        fi
    done
fi
[ -z "$BAT" ] && BAT=80
CHG=0
if [ -r /sys/devices/system/wario_charger/wario_charger0/charging ]; then
    CHG=$(cat /sys/devices/system/wario_charger/wario_charger0/charging 2>/dev/null | tr -dc '0-9')
    [ -z "$CHG" ] && CHG=0
fi
for lb in /var/local/mesquite/com.paperwhite.os/live_battery.js /var/local/mesquite/store/live_battery.js /var/local/mesquite/browser/live_battery.js /mnt/us/paperwhite-os/waf/live_battery.js; do
    echo "window.KINDLE_LIVE_BATTERY = { level: $BAT, charging: $CHG };" > "$lb" 2>/dev/null
done

# 2. Read free storage on /mnt/us
FREE_MB=$(df -m /mnt/us 2>/dev/null | tail -n 1 | awk '{print $4}')
if [ -n "$FREE_MB" ]; then
    FREE_STR="${FREE_MB} MB free"
else
    FREE_STR="2.6 GB free"
fi

# 3. Read current Wi-Fi SSID
CONN_SSID=$(wpa_cli -i wlan0 status 2>/dev/null | grep '^ssid=' | head -n 1 | cut -d= -f2 | tr -d '"\\')
[ -z "$CONN_SSID" ] && CONN_SSID="Home network"

echo "window.KINDLE_DEVICE_DATA = {" > "$OUT"
echo "  applianceMode: true," >> "$OUT"
echo "  setupRev: \"47\"," >> "$OUT"
echo "  battery: $BAT," >> "$OUT"
echo "  connectedWifi: \"$CONN_SSID\"," >> "$OUT"
echo "  storageFree: \"$FREE_STR\"," >> "$OUT"

# 4. Scan nearby Wi-Fi networks
echo "  wifiNetworks: [" >> "$OUT"
echo "    { ssid: \"$CONN_SSID\", signal: \"Connected\", secured: true, connected: true }," >> "$OUT"
wpa_cli -i wlan0 scan_results 2>/dev/null | tail -n +3 | awk -F'\t' '{print $5}' | sort -u | head -n 10 | while IFS= read -r net_ssid; do
    CLEAN_NET=$(echo "$net_ssid" | tr -d '"\\'\''')
    if [ -n "$CLEAN_NET" ] && [ "$CLEAN_NET" != "$CONN_SSID" ]; then
        echo "    { ssid: \"$CLEAN_NET\", signal: \"Available\", secured: true, connected: false }," >> "$OUT"
    fi
done
echo "  ]," >> "$OUT"

# 5. Recursively scan ALL books in /mnt/us/documents/ (including Calibre subfolders!)
echo "  books: [" >> "$OUT"

IDX=0
ARTS="circle lines dots triangle rosette square"
find /mnt/us/documents -type f \( -iname "*.azw3" -o -iname "*.azw" -o -iname "*.mobi" -o -iname "*.epub" -o -iname "*.pdf" -o -iname "*.kfx" -o -iname "*.prc" -o -iname "*.txt" \) 2>/dev/null | sort | while IFS= read -r f; do
    [ -f "$f" ] || continue
    BN=$(basename "$f")
    case "$BN" in
        KPPMainApp*|*.sdr|JAILBROKEN*|1_Full_Takeover*|2_Restore_Stock*|Paperwhite_OS*|Install_Paperwhite_OS*|*.sh) continue ;;
    esac
    EXT="${BN##*.}"
    RAW_TITLE="${BN%.*}"
    # Strip Amazon ASIN suffix like _B00... or _EBOK if present
    RAW_TITLE=$(echo "$RAW_TITLE" | sed 's/_B0[A-Z0-9]*$//; s/_EBOK$//')
    CLEAN_TITLE=$(echo "$RAW_TITLE" | tr '_' ' ' | tr -d '"\\'\''' | cut -c1-36)
    UPPER_TITLE=$(echo "$CLEAN_TITLE" | tr 'a-z' 'A-Z' | cut -c1-14)

    # Extract Author or Folder name from parent path
    PARENT_DIR=$(basename "$(dirname "$f")" | tr -d '"\\'\''')
    if [ "$PARENT_DIR" = "documents" ]; then
        AUTHOR_STR=$(echo "$EXT" | tr 'a-z' 'A-Z')
    else
        AUTHOR_STR=$(echo "$PARENT_DIR" | cut -c1-24)
    fi

    DARK="true"
    [ $((IDX % 2)) -eq 1 ] && DARK="false"
    ART=$(echo $ARTS | awk -v n=$(( (IDX % 6) + 1 )) '{print $n}')
    SAFE_PATH=$(echo "$f" | tr -d '"\\'\''')
    # Extract up to 3600 chars of clean readable text from .txt, .epub, .mobi, .azw, .azw3 for built-in E-Ink Reader!
    EXTRACTED=""
    case "$EXT" in
        txt|TXT|md|MD|html|HTML)
            EXTRACTED=$(sed 's/<[^>]*>/ /g' "$f" 2>/dev/null | tr '\r\n\t' '   ' | tr -d '"\\'\''' | tr -s ' ' | cut -c1-3600)
            ;;
        epub|EPUB)
            EXTRACTED=$(unzip -p "$f" "*.xhtml" "*.html" "*.htm" 2>/dev/null | sed 's/<style[^>]*>.*<\/style>/ /g; s/<[^>]*>/ /g' | tr '\r\n\t' '   ' | tr -d '"\\'\''' | tr -s ' ' | cut -c1-3600)
            ;;
        mobi|MOBI|azw|AZW|azw3|AZW3|prc|PRC)
            EXTRACTED=$(strings -n 14 "$f" 2>/dev/null | grep -v -E '^(EXTH|MOBI|BOOKMOBI|TPZ|FONT|RESC|BOUNDARY|kindle:|application/)' | sed 's/<[^>]*>/ /g' | tr '\r\n\t' '   ' | tr -d '"\\'\''' | tr -s ' ' | head -c 4200 | cut -c1-3600)
            ;;
    esac
    echo "    { id: \"book_$IDX\", title: \"$CLEAN_TITLE\", coverTitle: \"$UPPER_TITLE\", author: \"$AUTHOR_STR\", path: \"$SAFE_PATH\", extractedText: \"$EXTRACTED\", progress: 10, status: \"Readable\", dark: $DARK, downloaded: true, art: \"$ART\" }," >> "$OUT"
    IDX=$((IDX + 1))
done

echo "  ]" >> "$OUT"
echo "};" >> "$OUT"

cp -f "$OUT" "$OUT2" 2>/dev/null
cp -f "$OUT" "$OUT3" 2>/dev/null
cp -f "$OUT" "$OUT4" 2>/dev/null
cp -f "$OUT" /mnt/us/paperwhite-os/waf/device_data.js 2>/dev/null

# Always ensure Amazon default_status_bar is patched and hidden on wake/scan
mntroot rw 2>/dev/null || mount -o remount,rw / 2>/dev/null
if [ -f /usr/share/webkit-1.0/pillow/default_status_bar.html ]; then
    if [ ! -f /usr/share/webkit-1.0/pillow/default_status_bar.html.amazon_bak ]; then
        cp -a /usr/share/webkit-1.0/pillow/default_status_bar.html /usr/share/webkit-1.0/pillow/default_status_bar.html.amazon_bak 2>/dev/null
    fi
    cat << 'SBEOF' > /usr/share/webkit-1.0/pillow/default_status_bar.html
<!DOCTYPE html><html><head><style>html,body{display:none!important;height:0!important;overflow:hidden!important;}</style>
<script>window.onload=function(){if(window.nativeBridge){try{nativeBridge.setWindowSize(0,0);}catch(e){}try{nativeBridge.hideMe();}catch(e){}}};</script>
</head><body></body></html>
SBEOF
fi
mntroot ro 2>/dev/null || mount -o remount,ro / 2>/dev/null

if [ "$NEEDS_UI_RELOAD" = "1" ]; then
    killall mesquite 2>/dev/null
    sleep 1
    if ! pidof mesquite >/dev/null 2>&1; then nohup lipc-set-prop com.lab126.appmgrd start app://com.paperwhite.os >/dev/null 2>&1 & fi
    sleep 2
fi

lipc-set-prop -s com.lab126.pillow interrogatePillow '{"pillowId":"default_status_bar","function":"if(document.body){document.body.style.display=\"none\";}if(window.nativeBridge){nativeBridge.setWindowSize(0,0);nativeBridge.hideMe();}"}' 2>/dev/null
# do not dismiss active dialogs
# keep pillow enabled for wifi_wizard_dialog
for wid in $(xwininfo -root -tree 2>/dev/null | grep -i "mesquite" | awk '{print $1}'); do
    xprop -display :0 -id "$wid" -f WM_NAME 8s -set WM_NAME "L:A_N:application_PC:N_ID:com.paperwhite.os" 2>/dev/null
done
