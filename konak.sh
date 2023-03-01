#!/bin/bash
# v1 rev.1
#
# use to send telegram message & netcat output after disconnected event
# triggered automatically by netcheck
#

# bot and user ID
TG_CHAT_ID=XXXXX
TG_TOKEN=XXXX:XXXXXX

# send netcat output by bot to user
/root/net-status-openwrt/ngecat.sh > /root/net-status-openwrt/ngecek.txt 2>&1
NGETEXT=$(cat /root/net-status-openwrt/ngecek.txt)

curl -s --data "text=${NGETEXT}" \
     --data "parse_mode=markdown" \
     --data "chat_id=${TG_CHAT_ID}" \
     "https://api.telegram.org/bot${TG_TOKEN}/sendMessage"

rm /root/net-status-openwrt/ngecek.txt

# send alive text by bot to user
curl -s --data "text=Hey I'm UP!" \
     --data "parse_mode=markdown" \
     --data "chat_id=${TG_CHAT_ID}" \
     "https://api.telegram.org/bot${TG_TOKEN}/sendMessage"