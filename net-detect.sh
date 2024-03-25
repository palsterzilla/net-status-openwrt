#!/bin/bash
# v3.2
# Script for network detection and Telegram messaging
# Add to cron job
# example: * * * * * /root/net-status-openwrt/net-detect.sh

# Configuration
path=/root/net-status-openwrt
TG_CHAT_ID=123456789
TG_TOKEN=123456789:AAEGxxxx

# Function to reset modem
ngereset() {
  result=ERROR
  until [[ "$result" == *"OK"* ]]
  do
    reset=$(echo AT+RESET | atinout - /dev/ttyUSB2 -)
    if grep -q "$reset" <<< "*OK"; then
      result=OK
    elif grep -q "$reset" <<< "*ERROR"; then
      result=ERROR
    fi
  done
}

# Function to send message via Telegram
send_telegram_message() {
    curl -s --data "text=$1" \
         --data "parse_mode=markdown" \
         --data "chat_id=$TG_CHAT_ID" \
         "https://api.telegram.org/bot$TG_TOKEN/sendMessage"
}

# Perform the HTTP request and capture the HTTP status code
while IFS= read -r URL; do
  status=$(curl -s -o /dev/null -w "%{http_code}" -L "$URL")

  # Check if the HTTP status code is 200 (OK)
  if [ ${status} -eq 200 ]; then
    echo "OK" >> ${path}/ngonek.txt
  else
    echo "FAIL" >> ${path}/ngonek.txt
  fi
done < ${path}/list.txt

# Count percentage of connectivity
konek=$((100*$(grep -o "OK" ${path}/ngonek.txt | wc -l)/$(wc -l < ${path}/ngonek.txt)))

if [ $konek -ge 50 ]; then
  status=connected
  FILE=${path}/stamp
  if test -f "$FILE"; then
    rm ${path}/stamp
    # /usr/bin/jam.sh time.bmkg.go.id # enable this if using vmess, for time sync
    sleep 15
    send_telegram_message "Heyooo Im UP!"
  fi

elif [ $konek -lt 50 ]; then
  status=disconnected
  FILE=${path}/stamp
  if test ! -s "$FILE" && test ! -f "$FILE"; then
    touch ${path}/stamp
    echo $(date +%s) > ${path}/stamp
  fi
fi

rm ${path}/ngonek.txt

# execute after no connection
# reset after 1m
FILE=${path}/stamp
if test -f "$FILE" && [ $(expr $(date +%s) - $(cat ${path}/stamp)) == 60 ]; then
  ifdown wan1
  ngereset

# reset after 4m
elif test -f "$FILE" && [ $(expr $(date +%s) - $(cat ${path}/stamp)) == 240 ]; then
  ifdown wan1
  ngereset

# reboot after 7m
elif test -f "$FILE" && [ $(expr $(date +%s) - $(cat ${path}/stamp)) == 420 ]; then
  rm ${path}/stamp
  reboot
fi

echo $status