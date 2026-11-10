#!/bin/sh
# Name: 1. Install Paperwhite OS 4.7 (Full System Upgrade)
# Author: Paperwhite OS Contributors
# DontUseFBInk

export DISPLAY=:0
LIVE_MODE=0
[ "$1" = "--live" ] && LIVE_MODE=1
LOG="/mnt/us/paperwhite-os/takeover.log"
echo "=== Starting Paperwhite OS 4.7 Full Upgrade ($(date)) ===" > "$LOG"

rm -f /mnt/us/UNLOCK_STOCK_KINDLE 2>/dev/null
touch /mnt/us/DISABLE_CORE_DUMP 2>/dev/null

# Auto-clean old unneeded scripts, folders, and KPPMainApp crash logs
rm -f /mnt/us/documents/KPPMainApp* 2>/dev/null
rm -f /mnt/us/documents/Restore_Stock_Kindle.sh 2>/dev/null
rm -f /mnt/us/documents/Paperwhite_OS_Home.sh 2>/dev/null
rm -f /mnt/us/documents/1_Full_Takeover_Paperwhite_OS.sh 2>/dev/null
rm -f /mnt/us/documents/2_Restore_Stock_Kindle.sh 2>/dev/null
rm -rf /mnt/us/documents/Paperwhite-OS-Installer 2>/dev/null
rm -f /mnt/us/README.md 2>/dev/null


# 1. Remount rootfs read-write (/dev/mmcblk0p1)
mntroot rw >> "$LOG" 2>&1 || mount -o remount,rw / >> "$LOG" 2>&1

# 2. Stop old instances when running from terminal
[ "$LIVE_MODE" = "0" ] && killall mesquite 2>/dev/null
killall screensaver_watchdog.sh 2>/dev/null

# 3. ZERO-GLITCH SLEEP WALLPAPERS (Point 6):
# Permanently unload ad_screensaver and populate both /usr/share/blanket/screensaver/
# AND /var/local/adunits/ + /mnt/us/system/.assets/ so the Kindle's native hardware
# screensaver displays ONE custom wallpaper instantly with ZERO flashing or 2s delay!
lipc-set-prop com.lab126.blanket unload ad_screensaver 2>/dev/null
if [ -d /usr/share/blanket/screensaver ]; then
    if [ ! -d /usr/share/blanket/screensaver.stock_backup ]; then
        cp -rf /usr/share/blanket/screensaver /usr/share/blanket/screensaver.stock_backup >> "$LOG" 2>&1
    fi
    rm -f /usr/share/blanket/screensaver/*.png 2>/dev/null
    cp -f /mnt/us/paperwhite-os/wallpapers/bg_ss*.png /usr/share/blanket/screensaver/ 2>/dev/null
    chmod 644 /usr/share/blanket/screensaver/*.png 2>/dev/null
fi
# Also replace any cached ad screensaver images so ad_screensaver can never flash first
find /var/local/adunits /mnt/us/system/.assets -type f \( -name "*.png" -o -name "*.gif" -o -name "*.jpg" \) 2>/dev/null | while IFS= read -r adimg; do
    cp -f /mnt/us/paperwhite-os/wallpapers/bg_ss00.png "$adimg" 2>/dev/null
done

# 4. Install Paperwhite OS 4.7 WAF into com.paperwhite.os, browser, and store (Exact Paperwhite OS 4 procedure!)
mkdir -p /var/local/mesquite/com.paperwhite.os
ln -sf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/com.paperwhite.os/index.html 2>/dev/null || cp -rf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/com.paperwhite.os/index.html
cp -rf /mnt/us/paperwhite-os/waf/config.xml /var/local/mesquite/com.paperwhite.os/config.xml

if [ -d /var/local/mesquite/browser ] && [ ! -d /var/local/mesquite/browser.stock_backup ]; then
    cp -rf /var/local/mesquite/browser /var/local/mesquite/browser.stock_backup >> "$LOG" 2>&1
fi
mkdir -p /var/local/mesquite/browser
rm -rf /var/local/mesquite/browser/* 2>/dev/null
ln -sf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/browser/index.html 2>/dev/null || cp -rf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/browser/index.html
cp -rf /mnt/us/paperwhite-os/waf/browser_config.xml /var/local/mesquite/browser/config.xml

if [ -d /var/local/mesquite/store ] && [ ! -d /var/local/mesquite/store.stock_backup ]; then
    cp -rf /var/local/mesquite/store /var/local/mesquite/store.stock_backup >> "$LOG" 2>&1
fi
mkdir -p /var/local/mesquite/store
rm -rf /var/local/mesquite/store/* 2>/dev/null
ln -sf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/store/index.html 2>/dev/null || cp -rf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/store/index.html
cp -rf /mnt/us/paperwhite-os/waf/store_config.xml /var/local/mesquite/store/config.xml

mkdir -p /mnt/us/apps/com.paperwhite.os
cp -rf /mnt/us/paperwhite-os/waf/index.html /mnt/us/apps/com.paperwhite.os/index.html 2>/dev/null

# 5. Recursively scan all books in /mnt/us/documents/ & Wi-Fi networks
chmod +x /mnt/us/paperwhite-os/scan_books.sh
/mnt/us/paperwhite-os/scan_books.sh >> "$LOG" 2>&1

# 6. Repoint handlers in /var/local/appreg.db to Paperwhite OS
sqlite3 /var/local/appreg.db <<EOF
INSERT OR IGNORE INTO interfaces(interface) VALUES('application');
INSERT OR IGNORE INTO handlerIds(handlerId) VALUES('com.paperwhite.os');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.paperwhite.os','lipcId','com.paperwhite.os');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.paperwhite.os','command','/usr/bin/mesquite -l com.paperwhite.os -c file:///var/local/mesquite/com.paperwhite.os/');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.paperwhite.os','supportedOrientation','U');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.lab126.browser','command','/usr/bin/mesquite -l com.lab126.browser -c file:///var/local/mesquite/browser/');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.lab126.store','command','/usr/bin/mesquite -l com.lab126.store -c file:///var/local/mesquite/store/');
INSERT OR IGNORE INTO handlerIds(handlerId) VALUES('com.paperwhite.kterm');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.paperwhite.kterm','lipcId','com.paperwhite.kterm');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.paperwhite.kterm','command','/bin/sh /mnt/us/paperwhite-os/launch_kterm.sh');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('com.paperwhite.kterm','supportedOrientation','U');
EOF

# 7. Install Upstart boot jobs (single-event syntax for Kindle Upstart 0.6.5 compatibility)
cp -f /mnt/us/paperwhite-os/upstart_paperwhite_os.conf /etc/upstart/paperwhite_os.conf >> "$LOG" 2>&1
chmod 644 /etc/upstart/paperwhite_os.conf >> "$LOG" 2>&1
cat << 'UPEOF2' > /etc/upstart/paperwhite_os_gui.conf
description "Paperwhite OS 4.7 Framework Startup"
start on started framework
stop on stopping system
exec /bin/sh /mnt/us/paperwhite-os/boot_daemon.sh
UPEOF2
chmod 644 /etc/upstart/paperwhite_os_gui.conf >> "$LOG" 2>&1
chmod +x /mnt/us/paperwhite-os/boot_daemon.sh >> "$LOG" 2>&1
chmod +x /mnt/us/paperwhite-os/screensaver_watchdog.sh >> "$LOG" 2>&1

# 8. Replace Amazon KPPMainApp executable on /dev/mmcblk0p1 & Eradicate Amazon Top Status Bar
# Completely hide & disable Amazon default_status_bar (Pillow + X11 PC:N + rootfs patch)
lipc-set-prop -s com.lab126.pillow interrogatePillow '{"pillowId":"default_status_bar","function":"if(document.body){document.body.style.display="none";}if(window.nativeBridge){nativeBridge.setWindowSize(0,0);nativeBridge.hideMe();}"}' 2>/dev/null
# do not dismiss active dialogs
lipc-set-prop -s com.lab126.pillow interrogatePillow '{"pillowId":"default_status_bar","function":"if(document.body){document.body.style.display="none";}if(window.nativeBridge){nativeBridge.setWindowSize(0,0);nativeBridge.hideMe();}"}' 2>/dev/null
            # keep pillow enabled for wifi_wizard_dialog
# Keep statusbar daemon alive at 0x0 size so interrogatePillow (brightness/LIPC bridge) ALWAYS works!
stop statusbar 2>/dev/null
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
for wid in $(xwininfo -root -tree 2>/dev/null | grep -i "mesquite" | awk '{print $1}'); do
    xprop -display :0 -id "$wid" -f WM_NAME 8s -set WM_NAME "L:A_N:application_PC:N_ID:com.paperwhite.os" 2>/dev/null
done

# Purge any stuck com.lab126.transfer jobs so kterm never re-launches in a loop
killall -9 transfer 2>/dev/null
rm -f /var/local/transfer* /var/local/mesquite/transfer* 2>/dev/null

for KPP_BIN in /app/bin/KPPMainApp /app/bin/KPPMainAppV1 /app/bin/KPPMainAppV2 /usr/bin/KPPMainApp; do
    if [ -f "${KPP_BIN}.amazon_bak" ]; then
        cp -a "${KPP_BIN}.amazon_bak" "$KPP_BIN" 2>/dev/null
        chmod 755 "$KPP_BIN" 2>/dev/null
    fi
done

mntroot ro >> "$LOG" 2>&1 || mount -o remount,ro / >> "$LOG" 2>&1

# 9. Start Watchdog Daemon (Zero-glitch wake handler) & Launch Paperwhite OS 4.7 on Layer D (Full Amazon OS Lockdown!)
chmod +x /mnt/us/paperwhite-os/launch_kterm.sh 2>/dev/null
killall screensaver_watchdog.sh 2>/dev/null
nohup /mnt/us/paperwhite-os/screensaver_watchdog.sh >/dev/null 2>&1 &

chmod +x /mnt/us/paperwhite-os/auto_setup.sh 2>/dev/null
if [ "$LIVE_MODE" = "0" ]; then
    killall mesquite 2>/dev/null
    sleep 1
    nohup lipc-set-prop com.lab126.appmgrd start app://com.paperwhite.os >/dev/null 2>&1 &
    sleep 3
fi

if ! pidof mesquite >/dev/null 2>&1; then
    DISPLAY=:0 nohup /usr/bin/mesquite -l com.paperwhite.os -c file:///var/local/mesquite/com.paperwhite.os/ >/dev/null 2>&1 &
    sleep 2
fi

lipc-set-prop -s com.lab126.pillow interrogatePillow '{"pillowId":"default_status_bar","function":"if(document.body){document.body.style.display="none";}if(window.nativeBridge){nativeBridge.setWindowSize(0,0);nativeBridge.hideMe();}"}' 2>/dev/null
lipc-set-prop -i com.lab126.pillow dismissChrome 1 2>/dev/null
lipc-set-prop -s com.lab126.pillow disableEnablePillow "disable" 2>/dev/null
lipc-set-prop -s com.lab126.chromebar configureChrome '{"appId":"com.paperwhite.os","topNavBar":{"template":"none"}}' 2>/dev/null
lipc-set-prop -s com.lab126.chromebar configureChrome '{"appId":"com.lab126.store","topNavBar":{"template":"none"}}' 2>/dev/null

# Set valid AwesomeWM chromeless full-screen title (PC:N removes BOTH Amazon battery bar T and top settings bar S!)
for wid in $(xwininfo -display :0 -root -tree 2>/dev/null | grep -i "mesquite" | awk '{print $1}'); do
    xprop -display :0 -id "$wid" -f WM_NAME 8s -set WM_NAME "L:A_N:application_PC:N_ID:com.paperwhite.os" 2>/dev/null
done
# Hide any residual searchBar / topBar chrome windows
for cwid in $(xwininfo -display :0 -root -tree 2>/dev/null | grep -E "searchBar|topBar|titleBar" | awk '{print $1}'); do
    xprop -display :0 -id "$cwid" -f WM_NAME 8s -set WM_NAME "L:C_N:topBar_HIDE_ID:hiddenbar" 2>/dev/null
done
echo "=== Paperwhite OS 4.7 Upgrade Complete! ===" >> "$LOG"
echo "Paperwhite OS 4.7 configured! Switching screen..."
if [ "$LIVE_MODE" = "0" ]; then
    (sleep 1; killall kterm 2>/dev/null) &
fi
