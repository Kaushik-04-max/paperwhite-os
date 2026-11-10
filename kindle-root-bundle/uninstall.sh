#!/bin/sh
# Name: 2. Emergency Unlock — Restore Stock Kindle UI
# Author: Paperwhite OS Contributors
# DontUseFBInk

touch /mnt/us/UNLOCK_STOCK_KINDLE
killall screensaver_watchdog.sh 2>/dev/null
killall mesquite 2>/dev/null

mntroot rw 2>/dev/null || mount -o remount,rw / 2>/dev/null
rm -f /etc/upstart/paperwhite_os.conf
for KPP_BIN in /app/bin/KPPMainApp /app/bin/KPPMainAppV1 /app/bin/KPPMainAppV2 /usr/bin/KPPMainApp; do
    if [ -f "${KPP_BIN}.amazon_bak" ]; then
        mv -f "${KPP_BIN}.amazon_bak" "$KPP_BIN" 2>/dev/null
        chmod 755 "$KPP_BIN" 2>/dev/null
    fi
done
if [ -d /usr/share/blanket/screensaver.stock_backup ]; then
    rm -rf /usr/share/blanket/screensaver
    cp -rf /usr/share/blanket/screensaver.stock_backup /usr/share/blanket/screensaver
fi
if [ -d /var/local/mesquite/browser.stock_backup ]; then
    rm -rf /var/local/mesquite/browser
    cp -rf /var/local/mesquite/browser.stock_backup /var/local/mesquite/browser
fi
if [ -d /var/local/mesquite/store.stock_backup ]; then
    rm -rf /var/local/mesquite/store
    cp -rf /var/local/mesquite/store.stock_backup /var/local/mesquite/store
fi
if [ -f /usr/share/webkit-1.0/pillow/default_status_bar.html.amazon_bak ]; then
    mv -f /usr/share/webkit-1.0/pillow/default_status_bar.html.amazon_bak /usr/share/webkit-1.0/pillow/default_status_bar.html 2>/dev/null
fi
mntroot ro 2>/dev/null || mount -o remount,ro / 2>/dev/null

lipc-set-prop -s com.lab126.pillow disableEnablePillow "enable" 2>/dev/null
start statusbar 2>/dev/null
killall -9 KPPMainApp 2>/dev/null
lipc-set-prop com.lab126.appmgrd start app://com.lab126.booklet.home
