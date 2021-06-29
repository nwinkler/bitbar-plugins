#!/bin/bash

# <bitbar.title>simpleping</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Nils Winkler</bitbar.author>
# <bitbar.author.github>nwinkler</bitbar.author.github>
# <bitbar.desc>Send ping to one or more sites - based on the "bitping" plugin</bitbar.desc>
# <bitbar.dependencies></bitbar.dependencies>

# This is a plugin for Bitbar
# https://github.com/matryer/bitbar
#
# Author: Nils Winkler
# Based on original bitping/bitbar ping by Simon Hudson, Trung Đinh Quang, Grant Sherrick and Kent Karlsson.
# Theme from http://colorbrewer2.org/

RED_GREEN_THEME=("#d73027" "#fc8d59" "#fee08b" "#d9ef8b" "#91cf60" "#1a9850")

# Configuration

COLORS=("${RED_GREEN_THEME[@]}")
MENUFONT=""
FONT=""
MAX_PING=1000
SITES=(8.8.8.8) #Google DNS; SITES=(google.com youtube.com wikipedia.org github.com) using only one site is recommended for graph consistency
SITE_INDEX=0
PING_TIMES=
PING_COUNT=2
PING_TIMEOUT=2

# Make sure that the target folder exists
FOLDER_OUT="$HOME/Documents/PingTest"
mkdir -p "$FOLDER_OUT"

FILE_OUT="$FOLDER_OUT/simpleping.log"

#Uncomment if header row required in output file
#if [ ! -f "$FILE_OUT" ]; then
#    echo "date, host, response" >> $FILE_OUT
#fi

# Functions, etc

function colorize {

    if [ "$1" -ge $MAX_PING ]; then

        echo "${COLORS[0]}"

    elif [ "$1" -ge $((MAX_PING*6/10)) ]; then

        echo "${COLORS[1]}"

    elif [ "$1" -ge $((MAX_PING*4/10)) ]; then

        echo "${COLORS[2]}"

    elif [ "$1" -ge $((MAX_PING*2/10)) ]; then

        echo "${COLORS[3]}"

    elif [ "$1" -ge $((MAX_PING*1/10)) ]; then

        echo "${COLORS[4]}"

    else

        echo "${COLORS[5]}"

    fi

}

#Generate Output

RETRY=false

while [ $SITE_INDEX -lt ${#SITES[@]} ]; do
    NEXT_SITE="${SITES[$SITE_INDEX]}"
    NEXT_PING_TIME=$(ping -c "$PING_COUNT" -n -q -t "$PING_TIMEOUT" "$NEXT_SITE" 2>/dev/null | awk -F '/' 'END {printf "%.0f\n", $5}')

    if [ "$NEXT_PING_TIME" -eq 0 ]; then

        NEXT_PING_TIME=$MAX_PING

        if [ "$RETRY" == "true" ] ; then
            RETRY=false
        else
            RETRY=true

            # Try one more time
            continue
        fi
    fi

    if [ -z "$PING_TIMES" ]; then

        PING_TIMES=("$NEXT_PING_TIME")

    else

        PING_TIMES=("${PING_TIMES[@]}" "$NEXT_PING_TIME")

    fi

    SITE_INDEX=$(( SITE_INDEX + 1 ))

done

if [ $NEXT_PING_TIME -ge $MAX_PING ]; then

    MSG="DOWN"

else

    MSG="UP"

fi

echo "$MSG | color=$(colorize $NEXT_PING_TIME) $MENUFONT"
echo "---"

SITE_INDEX=0

while [ $SITE_INDEX -lt ${#SITES[@]} ]; do

    PING_TIME=${PING_TIMES[$SITE_INDEX]}

    echo "$(date '+%Y-%m-%d %H:%M:%S'), ${SITES[$SITE_INDEX]}, $PING_TIME" >> "$FILE_OUT"

    if [ "$PING_TIME" -eq $MAX_PING ]; then

        PING_TIME="FAIL"

    else

        PING_TIME="$PING_TIME ms | color=$(colorize $PING_TIME) $FONT"

    fi

    echo "${SITES[$SITE_INDEX]}: $PING_TIME"
    SITE_INDEX=$(( SITE_INDEX + 1 ))

done

echo "---"

echo "Refresh... | refresh=true"

if [ "$MSG" == "DOWN" ]; then
    osascript -e 'display notification "Network is down!" with title "Network Check" sound name "Submarine"'
fi
