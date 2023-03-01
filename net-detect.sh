#!/bin/bash
# v2 rev.0
#
path=/root/net-status-openwrt

ngecat() {
  nc -z -v -w5 $1 >/dev/null 2>&1
}

while IFS='' read -r LINE || [[ -n "$LINE" ]]; do
  ngecat "$LINE 443 80"

  # if connection OK
  if [ $? -eq 0 ]; then
    echo "OK" >> ${path}/ngonek.txt

  # if connection FAIL
  else
    echo "FAIL" >> ${path}/ngonek.txt
  fi
done < ${path}/list.txt

konek=$((100*$(grep -o "OK" ${path}/ngonek.txt | wc -l)/$(wc -l < ${path}/ngonek.txt)))
# if connected >=50%
if [ $konek -ge 50 ]; then
  status=connected

  FILE=${path}/stamp
  if test -f "$FILE"; then
    # echo "stamp exist, rm"
    rm ${path}/stamp
    /usr/bin/jam.sh time.bmkg.go.id
    sleep 15
    ${path}/konak.sh # > konak.txt 2>&1
    /etc/init.d/cloudflared restart
  fi

# if connected <50%
elif [ $konek -lt 50 ]; then
  status=disconnected

  FILE=${path}/stamp
  if test ! -s "$FILE" && test ! -f "$FILE"; then
    # echo "stamp not exist, touch"
    touch ${path}/stamp
    echo $(date +%s) > ${path}/stamp
  fi
fi

rm ${path}/ngonek.txt

# reset after 3m
FILE=${path}/stamp
if test -f "$FILE" && [ $(expr $(date +%s) - $(cat ${path}/stamp)) == 180 ]; then
  # echo 180
  ifdown wan1
  /etc/init.d/openclash restart
  echo AT+RESET | atinout - /dev/ttyUSB2 - # && sleep 3m && ifdown wan1 && sleep 6 && ifup wan1

# reset after 7m
elif test -f "$FILE" && [ $(expr $(date +%s) - $(cat ${path}/stamp)) == 420 ]; then
  # echo 420
  ifdown wan1
  /etc/init.d/openclash restart
  echo AT+RESET | atinout - /dev/ttyUSB2 -

# reboot after 12m
elif test -f "$FILE" && [ $(expr $(date +%s) - $(cat ${path}/stamp)) == 720 ]; then
  # echo 720
  rm ${path}/stamp
  reboot
fi

echo $status