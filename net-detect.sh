#!/bin/bash
# v3.3
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

# execute after connection timeout
FILE=${path}/stamp
current_time=$(date +%s)

if test -f "$FILE"; then
  stamp_time=$(cat ${path}/stamp)
  elapsed_time=$((current_time - stamp_time))

  if [ $elapsed_time -ge 60 ] && [ $elapsed_time -lt 120 ]; then
    ifdown wan1
    ngereset

  elif [ $elapsed_time -ge 240 ] && [ $elapsed_time -lt 300 ]; then
    ifdown wan1
    ngereset

  elif [ $elapsed_time -ge 420 ]; then
    rm ${path}/stamp
    reboot
  fi
fi

echo $status