#!/bin/bash
# v3.0
# Combined script for network detection and Telegram messaging

# Configuration
PATH=/root/net-status-openwrt
TG_CHAT_ID=XXXXX
TG_TOKEN=XXXX:XXXXXX

# Function to reset network
reset_network() {
    result=ERROR
    until [[ "$result" == *"OK"* ]]; do
        reset_output=$(echo AT+RESET | atinout - /dev/ttyUSB2 -)
        if grep -q "$reset_output" <<< "*OK"; then
            result=OK
        elif grep -q "$reset_output" <<< "*ERROR"; then
            result=ERROR
        fi
    done
}

# Function to check network using netcat
check_network() {
    nc -z -v -w5 "$1" >/dev/null 2>&1
}

# Function to send message via Telegram
send_telegram_message() {
    curl -s --data "text=$1" \
         --data "parse_mode=markdown" \
         --data "chat_id=$TG_CHAT_ID" \
         "https://api.telegram.org/bot$TG_TOKEN/sendMessage"
}

# Main function
main() {
    # Check network status
    while IFS='' read -r line || [[ -n "$line" ]]; do
        check_network "$line 443 80"

        if [ $? -eq 0 ]; then
            echo "OK" >> "$PATH/ngonek.txt"
        else
            echo "FAIL" >> "$PATH/ngonek.txt"
        fi
    done < "$PATH/list.txt"

    # Calculate connection percentage
    connected_count=$(grep -o "OK" "$PATH/ngonek.txt" | wc -l)
    total_count=$(wc -l < "$PATH/ngonek.txt")
    connection_percentage=$((100 * connected_count / total_count))

    # Determine status based on connection percentage
    if [ $connection_percentage -ge 50 ]; then
        status="connected"

        stamp_file="$PATH/stamp"
        if [ -f "$stamp_file" ]; then
            rm "$stamp_file"
            /usr/bin/jam.sh time.bmkg.go.id
            sleep 15
            reset_network
        fi

    elif [ $connection_percentage -lt 50 ]; then
        status="disconnected"

        stamp_file="$PATH/stamp"
        if [ ! -s "$stamp_file" ] && [ ! -f "$stamp_file" ]; then
            touch "$stamp_file"
            echo "$(date +%s)" > "$stamp_file"
        fi
    fi

    rm "$PATH/ngonek.txt"

    # Perform actions based on connection status and time
    if [ -f "$stamp_file" ]; then
        seconds_since_stamp=$(expr $(date +%s) - $(cat "$stamp_file"))

        if [ $seconds_since_stamp -eq 180 ] || [ $seconds_since_stamp -eq 420 ]; then
            ifdown wan1
            reset_network
        elif [ $seconds_since_stamp -eq 720 ]; then
            rm "$stamp_file"
            reboot
        fi
    fi

    echo "$status"

    # Send Telegram message and netcat output after disconnected event
    while IFS='' read -r line || [[ -n "$line" ]]; do  
        check_network "$line 443"
        if [ "$?" == 0 ]; then
            echo -e "$line\nport 443 (https) - OK"
        else
            echo -e "$line\nport 443 (https) - Inaccessible"
        fi

        check_network "$line 80"
        if [ "$?" == 0 ]; then
            echo -e "port 80 (www) - OK\n"
        else
            echo -e "port 80 (www) - Inaccessible\n"
        fi
    done < "$PATH/list.txt" | tee "$PATH/ngecek.txt"

    ngetext=$(cat "$PATH/ngecek.txt")

    send_telegram_message "$ngetext"
    send_telegram_message "Hey I'm UP!"

    rm "$PATH/ngecek.txt"
}

main
