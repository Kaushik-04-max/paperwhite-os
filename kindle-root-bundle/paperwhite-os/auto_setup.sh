#!/bin/sh
rm -f /var/local/transfer* /var/local/mesquite/transfer* 2>/dev/null
nohup /bin/sh /mnt/us/install.sh --live >/dev/null 2>&1 &
exit 0
