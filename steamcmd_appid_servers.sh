#!/bin/bash
# steamcmd_appid_servers.sh
# Author: Daniel Gibbs
# Website: http://danielgibbs.co.uk
# Version: 180826
# Description: Saves the complete list of all the appid their names in json and csv.

rootdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

echo "Creating steamcmd_appid_servers.json"
curl https://api.steampowered.com/ISteamApps/GetAppList/v2/ | jq '[.applist.apps[] | select(.name | contains("server","Server"))]' > steamcmd_appid_servers.json
echo "Creating steamcmd_appid_servers.csv"
cat steamcmd_appid_servers.json | jq -r '.[] | [.appid, .name] | @csv' > steamcmd_appid_servers.csv
echo "Creating steamcmd_appid_servers.md"
cat steamcmd_appid_servers.json | md-table > steamcmd_appid_servers.md
echo "exit"
exit
