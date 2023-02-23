#!/bin/bash
# v1
#
curr() {
  date +%s
}

stamp() {
  cat ./stamp
}

SERVER=api.telegram.org
PORT="443 80"
nc -z -v -w5 $SERVER $PORT >/dev/null 2>&1
result1=$?

# if connection OK
if [ "$result1" == 0 ]; then
  status=connected

  FILE=./stamp
  if test -f "$FILE"; then
    # echo "stamp exist, rm"
    rm ./stamp
    /usr/bin/jam.sh time.bmkg.go.id
    sleep 15
    /root/net-status-openwrt/konak.sh # > konak.txt 2>&1
  fi

# if connection FAIL
elif [ "$result1" != 0 ]; then
  status=disconnected

  FILE=./stamp
  if test ! -s "$FILE" && test ! -f "$FILE"; then
    # echo "not exist, touch"
    touch stamp
    # echo $(curr) > stamp
    echo $(date +%s) > stamp
  fi
fi

# reset after 3m
FILE=./stamp
if test -f "$FILE" && [ $(expr $(curr) - $(stamp)) == 180 ]; then
  # echo 180
  ifdown wan1
  /etc/init.d/openclash restart
  echo AT+RESET | atinout - /dev/ttyUSB2 - # && sleep 3m && ifdown wan1 && sleep 6 && ifup wan1

# reset after 7m
elif test -f "$FILE" && [ $(expr $(curr) - $(stamp)) == 420 ]; then
  # echo 420
  ifdown wan1
  /etc/init.d/openclash restart
  echo AT+RESET | atinout - /dev/ttyUSB2 -

# reboot after 12m
elif test -f "$FILE" && [ $(expr $(curr) - $(stamp)) == 720 ]; then
  # echo 720
  rm ./stamp
  reboot
fi

echo $status
# echo $(curr)
# echo $(stamp)

# expr $(curr) - $(stamp)