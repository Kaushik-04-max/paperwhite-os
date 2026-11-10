#!/bin/sh
export DISPLAY=:0
# Loop 1: Continuous Appliance Lockdown
(
    while true; do
        if [ -f /mnt/us/UNLOCK_STOCK_KINDLE ]; then
            exit 0
        fi
        BAT_TICK=$(( ${BAT_TICK:-0} + 1 ))
        PSTATE=$(lipc-get-prop com.lab126.powerd state 2>/dev/null || echo "active")
        if [ "$PSTATE" = "active" ]; then
            # Update live hardware battery % every ~24 seconds with zero UI lag
            if [ "$BAT_TICK" -ge 12 ]; then
                BAT_TICK=0
                LBAT=$(lipc-get-prop com.lab126.powerd battLevel 2>/dev/null | head -n 1 | tr -dc '0-9')
                [ -z "$LBAT" ] && LBAT=$(gasgauge-info -s 2>/dev/null | head -n 1 | tr -dc '0-9')
                LCHG=0
                [ -r /sys/devices/system/wario_charger/wario_charger0/charging ] && LCHG=$(cat /sys/devices/system/wario_charger/wario_charger0/charging 2>/dev/null | tr -dc '0-9')
                [ -z "$LCHG" ] && LCHG=0
                if [ -n "$LBAT" ]; then
                    for lbf in /var/local/mesquite/com.paperwhite.os/live_battery.js /var/local/mesquite/store/live_battery.js /mnt/us/paperwhite-os/waf/live_battery.js; do
                        echo "window.KINDLE_LIVE_BATTERY = { level: $LBAT, charging: $LCHG };" > "$lbf" 2>/dev/null
                    done
                fi
            fi

            if ! pidof kterm >/dev/null 2>&1; then
                if ! pidof mesquite >/dev/null 2>&1; then
                    nohup lipc-set-prop com.lab126.appmgrd start app://com.paperwhite.os >/dev/null 2>&1 &
                    sleep 3
                    if ! pidof mesquite >/dev/null 2>&1; then
                        DISPLAY=:0 nohup /usr/bin/mesquite -l com.paperwhite.os -c file:///var/local/mesquite/com.paperwhite.os/ >/dev/null 2>&1 &
                        sleep 2
                    fi
                fi
            fi

            if pidof mesquite >/dev/null 2>&1; then
                if ! xwininfo -display :0 -root -tree 2>/dev/null | grep -q "wifi_wizard_dialog"; then
                    for wid in $(xwininfo -display :0 -root -tree 2>/dev/null | grep -i "mesquite" | awk '{print $1}'); do
                        cur_wm=$(xprop -display :0 -id "$wid" WM_NAME 2>/dev/null)
                        case "$cur_wm" in
                            *PC:N*) ;;
                            *)
                                xprop -display :0 -id "$wid" -f WM_NAME 8s -set WM_NAME "L:A_N:application_PC:N_ID:com.paperwhite.os" 2>/dev/null
                                for cwid in $(xwininfo -display :0 -root -tree 2>/dev/null | grep -E "searchBar|topBar|titleBar" | awk '{print $1}'); do
                                    xprop -display :0 -id "$cwid" -f WM_NAME 8s -set WM_NAME "L:C_N:topBar_HIDE_ID:hiddenbar" 2>/dev/null
                                done
                                lipc-set-prop -s com.lab126.pillow interrogatePillow '{"pillowId":"default_status_bar","function":"if(document.body){document.body.style.display="none";}if(window.nativeBridge){nativeBridge.setWindowSize(0,0);nativeBridge.hideMe();}"}' 2>/dev/null
                                lipc-set-prop -i com.lab126.pillow dismissChrome 1 2>/dev/null
                                lipc-set-prop -s com.lab126.pillow disableEnablePillow "disable" 2>/dev/null
                                ;;
                        esac
                    done
                fi
            fi
        fi
        sleep 2
    done
) &

# Loop 2: Wake Handler (Zero-glitch sleep: native /usr/share/blanket/screensaver handles sleep in 1 single frame!)
lipc-wait-event -m com.lab126.powerd outOfScreenSaver,wakeupFromSuspend | while read event; do
    [ -f /mnt/us/UNLOCK_STOCK_KINDLE ] && exit 0
    case "$event" in
        *outOfScreenSaver*|*wakeupFromSuspend*)
            /mnt/us/paperwhite-os/scan_books.sh 2>/dev/null &
            lipc-set-prop -s com.lab126.pillow interrogatePillow '{"pillowId":"default_status_bar","function":"if(document.body){document.body.style.display="none";}if(window.nativeBridge){nativeBridge.setWindowSize(0,0);nativeBridge.hideMe();}"}' 2>/dev/null
            lipc-set-prop -i com.lab126.pillow dismissChrome 1 2>/dev/null
            lipc-set-prop -s com.lab126.pillow disableEnablePillow "disable" 2>/dev/null
            lipc-set-prop -s com.lab126.chromebar configureChrome '{"appId":"com.paperwhite.os","topNavBar":{"template":"none"}}' 2>/dev/null
            if ! pidof mesquite >/dev/null 2>&1; then nohup lipc-set-prop com.lab126.appmgrd start app://com.paperwhite.os >/dev/null 2>&1 & fi
            ;;
    esac
done
