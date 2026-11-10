#!/bin/sh
export DISPLAY=:0
if [ -f /tmp/pwos_boot_active.pid ] && kill -0 $(cat /tmp/pwos_boot_active.pid 2>/dev/null) 2>/dev/null; then
    exit 0
fi
echo $$ > /tmp/pwos_boot_active.pid

# Purge any stuck com.lab126.transfer retry queue so kterm never auto-launches on boot!
killall -9 transfer 2>/dev/null
rm -f /var/local/transfer* /var/local/mesquite/transfer* 2>/dev/null

lipc-wait-event -s 45 com.lab126.appmgrd appStarted 2>/dev/null || sleep 12
sleep 3

[ -f /mnt/us/UNLOCK_STOCK_KINDLE ] && exit 0

mkdir -p /var/local/mesquite/com.paperwhite.os
cp -rf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/com.paperwhite.os/index.html
cp -rf /mnt/us/paperwhite-os/waf/config.xml /var/local/mesquite/com.paperwhite.os/config.xml

mkdir -p /var/local/mesquite/browser
cp -rf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/browser/index.html
cp -rf /mnt/us/paperwhite-os/waf/browser_config.xml /var/local/mesquite/browser/config.xml

mkdir -p /var/local/mesquite/store
cp -rf /mnt/us/paperwhite-os/waf/index.html /var/local/mesquite/store/index.html
cp -rf /mnt/us/paperwhite-os/waf/store_config.xml /var/local/mesquite/store/config.xml

/mnt/us/paperwhite-os/scan_books.sh 2>/dev/null

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

lipc-set-prop com.lab126.blanket unload ad_screensaver 2>/dev/null
lipc-set-prop -s com.lab126.pillow interrogatePillow '{"pillowId":"default_status_bar","function":"if(document.body){document.body.style.display="none";}if(window.nativeBridge){nativeBridge.setWindowSize(0,0);nativeBridge.hideMe();}"}' 2>/dev/null
            # keep pillow enabled for wifi_wizard_dialog
# do not dismiss active dialogs
lipc-set-prop -i com.lab126.pillow dismissChrome 1 2>/dev/null
lipc-set-prop -s com.lab126.pillow disableEnablePillow "disable" 2>/dev/null
lipc-set-prop -s com.lab126.chromebar configureChrome '{"appId":"com.paperwhite.os","topNavBar":{"template":"none"}}' 2>/dev/null
lipc-set-prop -s com.lab126.chromebar configureChrome '{"appId":"com.lab126.store","topNavBar":{"template":"none"}}' 2>/dev/null
killall mesquite 2>/dev/null
sleep 1
nohup lipc-set-prop com.lab126.appmgrd start app://com.paperwhite.os >/dev/null 2>&1 &
sleep 3
if ! pidof mesquite >/dev/null 2>&1; then
    DISPLAY=:0 nohup /usr/bin/mesquite -l com.paperwhite.os -c file:///var/local/mesquite/com.paperwhite.os/ >/dev/null 2>&1 &
    sleep 2
fi
for wid in $(xwininfo -display :0 -root -tree 2>/dev/null | grep -i "mesquite" | awk '{print $1}'); do
    xprop -display :0 -id "$wid" -f WM_NAME 8s -set WM_NAME "L:A_N:application_PC:N_ID:com.paperwhite.os" 2>/dev/null
done

exec /bin/sh /mnt/us/paperwhite-os/screensaver_watchdog.sh
