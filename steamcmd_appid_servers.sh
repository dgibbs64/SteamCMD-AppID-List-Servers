#!/bin/bash
# steamcmd_appid_servers.sh
# Author: Daniel Gibbs & Robin Bourne
# Website: http://danielgibbs.co.uk
# Version: 191212
# Description: Saves the complete list of all the appid their names in json and csv.

# Static variables
rootdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Downloads the source data files for analysis.
download_steam_files() {
  if [ ! -f "steamcmd_getapplist.json" ]; then
    echo "Creating steamcmd_appid.json"
    curl https://api.steampowered.com/ISteamApps/GetAppList/v2/ | jq -r '.' > ${tempdir}/steamcmd_getapplist.json
  fi
}

tempdir="$(mktemp -d)"

download_steam_files

echo "Creating steamcmd_appid_servers.json"
steamservers=$(jq '[.applist.apps[] | select(.name | contains("server","Server"))]' "${tempdir}/steamcmd_getapplist.json" | jq -s '.[]|sort_by(.appid)')
#echo "${steamservers}" >steamcmd_appid_servers.json

echo "Generate SteamCMD commands"
steamcommands=$(jq -n "${steamservers}" | jq -r '.[] | [.appid] | @csv' | sed 's/^/tmux send-keys "app_status /' | sed 's/$/" ENTER/')

# Linux analysis session
echo "Generate SteamCMD commands for Linux analysis session"
echo "${steamcommands//send-keys/send-keys -t tmux-linux}" >> tmux_steam_server_commands_linux.sh
echo "tmux send-keys -t tmux-linux \"exit\" ENTER" >> tmux_steam_server_commands_linux.sh

echo "Start Tmux Linux analysis session"
touch tmux_steam_server_output_linux.txt
tmux new -s "tmux-linux" -d 'steamcmd +login anonymous' \; pipe-pane "cat > tmux_steam_server_output_linux.txt"
echo ""
echo "Wait for SteamCMD prompt on Linux analysis session"
while ! grep -q "Steam>" tmux_steam_server_output_linux.txt; do
  echo -n "."
  sleep 1
done
echo ""

echo "Execute SteamCMD commands for Linux analysis session"
chmod +x tmux_steam_server_commands_linux.sh
./tmux_steam_server_commands_linux.sh &

# wait for the tmux session to finish
echo ""
echo "Wait for the linux analysis session to finish"
while [ "$(tmux ls | grep -c "tmux-linux")" -ne "0" ]; do
  echo -n "."
  sleep 1
done
echo ""

# Generate csv and json for Linux analysis session
pcre2grep -M -o1 -o2 --om-separator=\; 'AppID ([0-9]{1,8})[\s\S]*?release state: (.*)$' tmux_steam_server_output_linux.txt > tmux_steam_server_linux.csv

# convert the CSV to JSON
jq -Rsn '
	[inputs
	 | . / "\r\n"
	 | (.[] | select((. | length) > 0) | . / ";") as $input
	 | {"appid": $input[0]|tonumber, "subscriptionlinux": $input[1]}
	]
' < tmux_steam_server_linux.csv > tmux_steam_server_linux.json

# Windows analysis session
echo "Generate SteamCMD commands for Windows analysis session"
echo "${steamcommands//send-keys/send-keys -t tmux-windows}" >> tmux_steam_server_commands_windows.sh
echo "tmux send-keys -t tmux-windows \"exit\" ENTER" >> tmux_steam_server_commands_windows.sh

echo "Start Tmux Windows analysis session"
touch tmux_steam_server_output_windows.txt
tmux new -s "tmux-windows" -d 'steamcmd +@sSteamCmdForcePlatformType windows +login anonymous' \; pipe-pane "cat > tmux_steam_server_output_windows.txt"
echo ""
echo "Wait for SteamCMD prompt on Windows analysis session"
while ! grep -q "Steam>" tmux_steam_server_output_windows.txt; do
  echo -n "."
  sleep 1
done
echo ""

echo "Execute SteamCMD commands for Windows analysis session"
chmod +x tmux_steam_server_commands_windows.sh
./tmux_steam_server_commands_windows.sh &

# wait for the tmux session to finish
echo ""
echo "Wait for the Windows analysis session to finish"
while [ "$(tmux ls | wc -l)" -ne "0" ]; do
  echo -n "."
  sleep 1
done
echo ""

# Generate csv and json for Windows analysis session
pcre2grep -M -o1 -o2 --om-separator=\; 'AppID ([0-9]{1,8})[\s\S]*?release state: (.*)$' tmux_steam_server_output_windows.txt > tmux_steam_server_windows.csv

# convert the CSV to JSON
jq -Rsn '
	[inputs
	 | . / "\r\n"
	 | (.[] | select((. | length) > 0) | . / ";") as $input
	 | {"appid": $input[0]|tonumber, "subscriptionwindows": $input[1]}
	]
' < tmux_steam_server_windows.csv > tmux_steam_server_windows.json

# Merge Linux and Windows data
echo "Adding Linux compatibility information."
jq '[.[] | .linux = (.subscriptionlinux | contains("Invalid Platform") | not ) and (.subscriptionlinux | contains("unknown") | not )]' < tmux_steam_server_linux.json > tmux_steam_server_linux.json$$
mv tmux_steam_server_linux.json$$ tmux_steam_server_linux.json

echo "Adding Windows compatibility information."
jq '[.[] | .windows = (.subscriptionwindows | contains("Invalid Platform") | not ) and (.subscriptionwindows | contains("unknown") | not )]' < tmux_steam_server_windows.json > tmux_steam_server_windows.json$$
mv tmux_steam_server_windows.json$$ tmux_steam_server_windows.json

echo "Merging information."
jq -s '[ .[0] + .[1] + .[2] | group_by(.appid)[] | add]' steamcmd_appid_servers.json tmux_steam_server_linux.json tmux_steam_server_windows.json > steamcmd_appid_servers.json$$
mv steamcmd_appid_servers.json$$ steamcmd_appid_servers.json

# Remove False positives
echo "Filtering false positives."
cat steamcmd_appid_servers.json | jq 'map(select(.appid != 514900 and .appid != 559480))' > steamcmd_appid_servers.json$$
mv steamcmd_appid_servers.json$$ steamcmd_appid_servers.json

echo "Creating steamcmd_appid_servers.csv"
cat steamcmd_appid_servers.json | jq -r '.[] | [.appid, .name, .subscriptionlinux, .subscriptionwindows, .linux, .windows] | @csv' > steamcmd_appid_servers.csv

echo "Creating steamcmd_appid_servers.md"
cat steamcmd_appid_servers.json | md-table > steamcmd_appid_servers.md

cat steamcmd_appid_servers.json | jq '[.[] | select(.linux == true)]' | jq 'map( delpaths( [["linux"], ["windows"]] ))' | jq -s '.[]|sort_by(.appid)' > steamcmd_appid_servers_linux.json

echo "Creating steamcmd_appid_servers_linux.csv"
cat steamcmd_appid_servers_linux.json | jq -r '.[] | [.appid, .name, .subscriptionlinux, .subscriptionwindows, .linux, .windows] | @csv' > steamcmd_appid_servers_linux.csv

echo "Creating steamcmd_appid_servers_linux.md"
cat steamcmd_appid_servers_linux.json | jq -r '.[] | [.appid, .name, .subscriptionlinux, .subscriptionwindows, .linux, .windows]' | md-table > steamcmd_appid_servers_linux.md

exit
