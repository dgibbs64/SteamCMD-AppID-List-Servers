#!/bin/bash
# steamcmd_appid-servers.sh
# Author: Daniel Gibbs
# Website: http://danielgibbs.co.uk
# Version: 180826
# Description: Saves the complete list of all the appid their names in json and csv.

rootdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

echo "Creating steamcmd_appid-servers.json"
curl https://api.steampowered.com/ISteamApps/GetAppList/v2/ | jq -c '.applist.apps[] | select(.name | contains("server","Server"))' > steamcmd_appid-servers.json
echo "Creating steamcmd_appid-servers.csv"
cat steamcmd_appid-servers.json | jq '.applist.apps[]' | jq -r '[.appid, .name] | @csv' > steamcmd_appid-servers.csv
echo "Creating steamcmd_appid-servers.md"
cat steamcmd_appid-servers.json | jq '.applist[]' | md-table > steamcmd_appid-servers.md
echo "exit"
exit