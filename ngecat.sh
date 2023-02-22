#!/bin/bash
# v2 rev.0
#
# get netcat output (shorter), checked from list.txt
#
ngecat() {
  nc -z -v -w5 $1 >/dev/null 2>&1
}

while IFS='' read -r LINE || [[ -n "$LINE" ]]; do  

  # check 443 (https) port
  ngecat "$LINE 443"
  if [ "$?" == 0 ]; then
    echo -e "$LINE\nport 443 (https) - OK"
  else
    echo -e "$LINE\nport 443 (https) - Inaccesible"
  fi

  # check 80 (www) port
  ngecat "$LINE 80"
  if [ "$?" == 0 ]; then
    echo -e "port 80 (www) - OK\n"
  else
    echo -e "port 80 (www) - Inaccesible\n"
  fi

done < /root/net-status-openwrt/list.txt