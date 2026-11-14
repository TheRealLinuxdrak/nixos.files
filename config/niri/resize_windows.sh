#!/bin/bash

niri msg action do-screen-transition --delay-ms=300

active_id=$(niri msg -j focused-window | jq -r '.id')
workspace_id=$(niri msg -j focused-window | jq -r '.workspace_id')

for id in $(niri msg -j windows | jq -r ".[] | select(.workspace_id == $workspace_id) | .id"); do
    niri msg action focus-window --id "$id"
    niri msg action switch-preset-column-width
done

niri msg action focus-window --id "$active_id"
