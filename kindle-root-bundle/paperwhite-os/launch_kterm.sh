#!/bin/sh
export DISPLAY=:0
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/mnt/us/kterm/bin:/var/local/kmc/bin:/mnt/us/libkh/bin"
export HOME="/mnt/us"
export SHELL="/bin/sh"
export TERM="xterm"

# 1. Immediately abort & wipe com.lab126.transfer queue so transferd NEVER retries or loops kterm!
rm -f /var/local/transfer* /var/local/mesquite/transfer* 2>/dev/null
(sleep 1; killall -9 transfer 2>/dev/null; rm -f /var/local/transfer* 2>/dev/null) &

# 2. If kterm is already running or just exited within 3 seconds, do NOT launch a second copy!
if pidof kterm >/dev/null 2>&1; then
    exit 0
fi
if [ -f /tmp/pwos_kterm_cooldown ]; then
    exit 0
fi
touch /tmp/pwos_kterm_cooldown

# 3. Spawn kterm in a detached subshell while keeping mesquite (Paperwhite OS) alive underneath!
#    That way, when you tap Quit in kterm, kterm closes once and Paperwhite OS is immediately visible underneath
#    (the stock Kindle home screen is NEVER exposed!).
(
    KB_XML=$(ls /mnt/us/kterm/layouts/*300*.xml /mnt/us/kterm/layouts/*200*.xml /mnt/us/kterm/layouts/*.xml /mnt/us/extensions/kterm/layouts/*.xml 2>/dev/null | head -n 1)
    # Promote kterm window to L:D 1 second after it opens so it sits cleanly above mesquite on Layer D
    (
        sleep 1
        for kwid in $(xwininfo -display :0 -root -tree 2>/dev/null | grep -i "kterm" | awk '{print $1}'); do
            xprop -display :0 -id "$kwid" -f WM_NAME 8s -set WM_NAME "L:D_N:application_PC:N_ID:com.paperwhite.kterm" 2>/dev/null
        done
    ) &
    cd /mnt/us
    if [ -x /mnt/us/kterm/bin/kterm ]; then
        if [ -n "$KB_XML" ]; then
            /mnt/us/kterm/bin/kterm -k 1 -l "$KB_XML" -e /bin/sh
        else
            /mnt/us/kterm/bin/kterm -k 1 -e /bin/sh
        fi
    elif [ -f /mnt/us/kterm/bin/kterm.sh ]; then
        cd /mnt/us/kterm/bin && /bin/sh /mnt/us/kterm/bin/kterm.sh
    elif [ -f /mnt/us/kterm/kterm.sh ]; then
        cd /mnt/us/kterm && /bin/sh /mnt/us/kterm/kterm.sh
    elif [ -f /mnt/us/extensions/kterm/bin/kterm.sh ]; then
        cd /mnt/us/extensions/kterm && /bin/sh /mnt/us/extensions/kterm/bin/kterm.sh
    elif [ -x /var/local/kmc/bin/kpm ]; then
        /var/local/kmc/bin/kpm launch kterm
    fi

    # Keep a 4-second cooldown after kterm exits so any stray transfer retry is ignored
    touch /tmp/pwos_kterm_cooldown
    killall -9 transfer 2>/dev/null
    rm -f /var/local/transfer* 2>/dev/null

    # Ensure Paperwhite OS is immediately locked in front on Layer D
    if ! pidof mesquite >/dev/null 2>&1; then
        nohup lipc-set-prop com.lab126.appmgrd start app://com.paperwhite.os >/dev/null 2>&1 &
        sleep 1
    fi
    for wid in $(xwininfo -display :0 -root -tree 2>/dev/null | grep -i "mesquite" | awk '{print $1}'); do
        xprop -display :0 -id "$wid" -f WM_NAME 8s -set WM_NAME "L:A_N:application_PC:N_ID:com.paperwhite.os" 2>/dev/null
    done
    sleep 3
    rm -f /tmp/pwos_kterm_cooldown
) >/dev/null 2>&1 &

exit 0
