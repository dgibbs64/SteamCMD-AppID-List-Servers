#!/bin/bash
# steamcmd_appid_servers.sh
# Author: Daniel Gibbs & Robin Bourne
# Website: http://danielgibbs.co.uk
# Version: 180922
# Description: Saves the complete list of all the appid their names in json and csv.

#declare variables
attempt_counter=0
max_attempts=5
time_to_wait=30

echo "Downloading temporary file steamcmd_appid_list.json"
until $(curl --fail -o steamcmd_appid_list.json https://api.steampowered.com/ISteamApps/GetAppList/v2/); do
  if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Max attempts reached. Aborting"
      exit 1
    fi
    attempt_counter=$((attempt_counter+1))
    echo "Download failed (attempt ${attempt_counter} of ${max_attempts}). Waiting ${time_to_wait} seconds until trying again"

  sleep ${time_to_wait}
done

echo "Creating steamcmd_appid_servers.json"
cat steamcmd_appid_list.json | jq '[.applist.apps[] | select(.name | contains("server","Server"))]'| jq -s '.[]|sort_by(.appid)' > steamcmd_appid_servers.json

echo "Creating steamcmd_appid_servers.csv"
cat steamcmd_appid_servers.json | jq -r '.[] | [.appid, .name] | @csv' > steamcmd_appid_servers.csv

echo "Creating steamcmd_appid_servers.md"
cat steamcmd_appid_servers.json | md-table > steamcmd_appid_servers.md

echo "exit"
exit
