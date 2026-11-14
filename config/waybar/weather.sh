#!/usr/bin/env bash

weather_data=$(curl -s 'wttr.in/Praha?format=%C|%t')

if [[ -z "$weather_data" || "$weather_data" == *"Sorry"* || "$weather_data" == *"Unknown"* ]]; then
    echo "N/A 󰖐"
    exit 0
fi

condition=$(echo "$weather_data" | awk -F '|' '{print $1}' | tr '[:upper:]' '[:lower:]' | xargs)
temp=$(echo "$weather_data" | awk -F '|' '{print $2}' | sed 's/+//' | xargs)

case "$condition" in
    *clear*|*sunny*)           icon="󰖙" ;; 
    *partly*cloudy*)           icon="󰖕" ;; 
    *cloudy*|*overcast*)       icon="󰖐" ;; 
    *rain*|*drizzle*|*shower*) icon="󰖖" ;; 
    *snow*|*ice*)              icon="󰖘" ;; 
    *thunder*|*storm*)         icon="󰖓" ;; 
    *fog*|*mist*)              icon="󰖑" ;; 
    *)                         icon="󰖐" ;; 
esac

echo "$temp $icon"
