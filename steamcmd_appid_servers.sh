#!/bin/bash
# steamcmd_appid_servers.sh
# Author: Daniel Gibbs & Robin Bourne
# Website: http://danielgibbs.co.uk
# Version: 220821
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
jq '[.applist.apps[] | select(.name | contains("server","Server"))]' "${tempdir}/steamcmd_getapplist.json" | jq -s '.[]|sort_by(.appid)' > "${tempdir}/steamcmd_servers.json"
#echo "${steamservers}" >steamcmd_appid_servers.json

echo "Generate SteamCMD commands"
steamcommands=$(jq -r '.[] | [.appid] | @csv' "${tempdir}/steamcmd_servers.json" | sed 's/^/tmux send-keys "app_status /' | sed 's/$/" ENTER/')
# Linux analysis session
echo "Generate SteamCMD commands for Linux analysis session"
echo "${steamcommands//send-keys/send-keys -t tmux-linux}" >> ${tempdir}/tmux_steam_server_commands_linux.sh
echo "tmux send-keys -t tmux-linux \"exit\" ENTER" >> ${tempdir}/tmux_steam_server_commands_linux.sh

echo "Start Tmux Linux analysis session"
touch ${tempdir}/tmux_steam_server_output_linux.txt
tmux new -s "tmux-linux" -d 'steamcmd +login anonymous' \; pipe-pane "cat > ${tempdir}/tmux_steam_server_output_linux.txt"
echo ""
echo "Wait for SteamCMD prompt on Linux analysis session"
while ! grep -q "Steam>" ${tempdir}/tmux_steam_server_output_linux.txt; do
  echo -n "."
  sleep 1
done
echo ""

echo "Execute SteamCMD commands for Linux analysis session"
chmod +x ${tempdir}/tmux_steam_server_commands_linux.sh
${tempdir}//tmux_steam_server_commands_linux.sh &

echo ""
echo "Wait for the linux analysis session to finish"
while [ "$(tmux ls | grep -c "tmux-linux")" -ne "0" ]; do
  echo -n "."
  sleep 1
done
echo ""

# Generate csv and json for Linux analysis session
pcre2grep -M -o1 -o2 --om-separator=\; 'AppID ([0-9]{1,8})[\s\S]*?release state: (.*)$' ${tempdir}/tmux_steam_server_output_linux.txt > ${tempdir}/tmux_steam_server_linux.csv

# convert the CSV to JSON
jq -Rsn '
	[inputs
	 | . / "\r\n"
	 | (.[] | select((. | length) > 0) | . / ";") as $input
	 | {"appid": $input[0]|tonumber, "subscriptionlinux": $input[1]}
	]
' < ${tempdir}/tmux_steam_server_linux.csv > ${tempdir}/tmux_steam_server_linux.json

# Windows analysis session
echo "Generate SteamCMD commands for Windows analysis session"
echo "${steamcommands//send-keys/send-keys -t tmux-windows}" >> ${tempdir}/tmux_steam_server_commands_windows.sh
echo "tmux send-keys -t tmux-windows \"exit\" ENTER" >> ${tempdir}/tmux_steam_server_commands_windows.sh

echo "Start Tmux Windows analysis session"
touch ${tempdir}/tmux_steam_server_output_windows.txt
tmux new -s "tmux-windows" -d 'steamcmd +@sSteamCmdForcePlatformType windows +login anonymous' \; pipe-pane "cat > ${tempdir}/tmux_steam_server_output_windows.txt"
echo ""
echo "Wait for SteamCMD prompt on Windows analysis session"
while ! grep -q "Steam>" ${tempdir}/tmux_steam_server_output_windows.txt; do
  echo -n "."
  sleep 1
done
echo ""

echo "Execute SteamCMD commands for Windows analysis session"
chmod +x ${tempdir}/tmux_steam_server_commands_windows.sh
${tempdir}/tmux_steam_server_commands_windows.sh &

# wait for the tmux session to finish
echo ""
echo "Wait for the Windows analysis session to finish"
while [ "$(tmux ls | wc -l)" -ne "0" ]; do
  echo -n "."
  sleep 1
done
echo ""

# Generate csv and json for Windows analysis session
pcre2grep -M -o1 -o2 --om-separator=\; 'AppID ([0-9]{1,8})[\s\S]*?release state: (.*)$' ${tempdir}/tmux_steam_server_output_windows.txt > ${tempdir}/tmux_steam_server_windows.csv

# convert the CSV to JSON
jq -Rsn '
	[inputs
	 | . / "\r\n"
	 | (.[] | select((. | length) > 0) | . / ";") as $input
	 | {"appid": $input[0]|tonumber, "subscriptionwindows": $input[1]}
	]
' < ${tempdir}/tmux_steam_server_windows.csv > ${tempdir}/tmux_steam_server_windows.json

echo "Adding Linux compatibility information."
jq '[.[] | .linux = (.subscriptionlinux | contains("Invalid Platform") | not ) and (.subscriptionlinux | contains("unknown") | not )]' < ${tempdir}/tmux_steam_server_linux.json > ${tempdir}/tmux_steam_server_linux.json$$
mv ${tempdir}/tmux_steam_server_linux.json$$ ${tempdir}/tmux_steam_server_linux.json

echo "Adding Windows compatibility information."
jq '[.[] | .windows = (.subscriptionwindows | contains("Invalid Platform") | not ) and (.subscriptionwindows | contains("unknown") | not )]' < ${tempdir}/tmux_steam_server_windows.json > ${tempdir}/tmux_steam_server_windows.json$$
mv ${tempdir}/tmux_steam_server_windows.json$$ ${tempdir}/tmux_steam_server_windows.json

echo "Merging information."
jq -s '[ .[0] + .[1] + .[2] | group_by(.appid)[] | add]' "${tempdir}/tmux_steam_server_linux.json" "${tempdir}/tmux_steam_server_windows.json" > ${tempdir}/steamcmd_appid_servers.json$$
mv ${tempdir}/steamcmd_appid_servers.json$$ ${tempdir}/steamcmd_appid_servers.json

# Add name to each appid
jq '[JOIN(INDEX(input[]; (.appid|tostring)); .[]; (.appid|tostring); add)]' "${tempdir}/steamcmd_appid_servers.json" "${tempdir}/steamcmd_servers.json" > ${tempdir}/steamcmd_appid_servers.json$$
mv ${tempdir}/steamcmd_appid_servers.json$$ ${tempdir}/steamcmd_appid_servers.json

# Remove False positives
echo "Filtering false positives"
jq 'map(select(.appid != 514900 and .appid != 559480))' ${tempdir}/steamcmd_appid_servers.json > ${tempdir}/steamcmd_appid_servers.json$$
mv ${tempdir}/steamcmd_appid_servers.json$$ steamcmd_appid_servers.json

echo "Creating steamcmd_appid_servers.csv"
cat steamcmd_appid_servers.json | jq -r '.[] | [.appid, .name, .subscriptionlinux, .subscriptionwindows, .linux, .windows] | @csv' > steamcmd_appid_servers.csv

# Linux Specific files
cat steamcmd_appid_servers.json | jq '[.[] | select(.linux == true)]' | jq 'map( delpaths( [["subscriptionwindows"], ["windows"], ["subscriptionlinux"], ["linux"]] ))' | jq -s '.[]|sort_by(.appid)' > steamcmd_appid_servers_linux.json
cat steamcmd_appid_servers_linux.json | jq -r '.[] | [.appid, .name] | @csv' > steamcmd_appid_servers_linux.csv

# Windows Specific files
cat steamcmd_appid_servers.json | jq '[.[] | select(.windows == true)]' | jq 'map( delpaths( [["subscriptionwindows"], ["windows"], ["subscriptionlinux"], ["linux"]] ))' | jq -s '.[]|sort_by(.appid)' > steamcmd_appid_servers_windows.json
cat steamcmd_appid_servers_linux.json | jq -r '.[] | [.appid, .name] | @csv' > steamcmd_appid_servers_windows.csv