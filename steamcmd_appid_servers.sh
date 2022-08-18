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
    curl https://api.steampowered.com/ISteamApps/GetAppList/v2/ | jq -r '.' > steamcmd_getapplist.json
  fi
}

# Generate a list of commands to send to SteamCMD.
# Parameter 1: JSON content to parse as an array of relevant entities.
# Returns: Output as string.
generate_commands() {
  local input_json="${1}"
  local temp_file="$(mktemp)"
  echo "${input_json}" > "${temp_file}"
  local output="$(jq -n -f "${temp_file}" | jq -r '.[] | [.appid] | @csv' | sed 's/^/tmux send-keys "app_status /' | sed 's/$/" ENTER/')"
  echo "${output}"
  rm "${temp_file}"
}

# pre-requirements.
install_steamcmd
download_steam_files

echo "Creating steamcmd_appid_servers.json"
steam_servers=$(cat steamcmd_getapplist.json | jq '[.applist.apps[] | select(.name | contains("server","Server"))]' | jq -s '.[]|sort_by(.appid)')
echo "${steam_servers}" > steamcmd_appid_servers.json

echo "Generate tmux script to check servers platform."
output=$(generate_commands "${steam_servers}")
echo "${output}" > tmux_steam_server_commands_linux.sh
chmod +x tmux_steam_server_commands_linux.sh

sed -i "s/send-keys/send-keys -t tmux-linux/" tmux_steam_server_commands_linux.sh
echo "tmux send-keys -t tmux-linux \"exit\" ENTER" >> tmux_steam_server_commands_linux.sh

echo "Spin up 1 TMUX in Linux mode."
if [ ! -f "tmux_steam_server_output_linux.txt" ]; then
  touch "tmux_steam_server_output_linux.txt"
fi
tmux new -s "tmux-linux" -d 'steamcmd +login anonymous' \; pipe-pane "cat > ./tmux_steam_server_output_linux.txt"
echo ""
echo "Waiting for SteamCMD prompt."
while ! grep -q "Steam>" tmux_steam_server_output_linux.txt; do
  echo -n "."
  sleep 1
done

# executing commands to windows shell and awaiting finish.
./tmux_steam_server_commands_linux.sh &

# wait for the tmux session to finish
echo ""
echo "Waiting for the tmux session to finish."
while [ "$(tmux ls | wc -l)" -ne "0" ]; do
  echo -n "."
  sleep 1
done

echo "Generate tmux script to check servers platform."
output=$(generate_commands "${steam_servers}")
echo "${output}" > tmux_steam_server_commands_windows.sh
chmod +x tmux_steam_server_commands_windows.sh

sed -i "s/send-keys/send-keys -t tmux-windows/" tmux_steam_server_commands_windows.sh
echo "tmux send-keys -t tmux-windows \"exit\" ENTER" >> tmux_steam_server_commands_windows.sh

echo "Spin up 1 TMUX in Windows mode."
if [ ! -f "tmux_steam_server_output_windows.txt" ]; then
  touch "tmux_steam_server_output_windows.txt"
fi
tmux new -s "tmux-windows" -d 'steamcmd +@sSteamCmdForcePlatformType windows +login anonymous' \; pipe-pane "cat > ./tmux_steam_server_output_windows.txt"
echo ""
echo "Waiting for SteamCMD prompt."
while ! grep -q "Steam>" tmux_steam_server_output_windows.txt; do
  echo -n "."
  sleep 1
done

# executing commands to windows shell and awaiting finish.
./tmux_steam_server_commands_windows.sh &

# wait for the tmux session to finish
echo ""
echo "Waiting for the tmux session to finish."
while [ "$(tmux ls | wc -l)" -ne "0" ]; do
  echo -n "."
  sleep 1
done

pcre2grep -M -o1 -o2 --om-separator=\; 'AppID ([0-9]{1,8})[\s\S]*?release state: (.*)$' tmux_steam_server_output_linux.txt > tmux_steam_server_linux.csv

# convert the CSV to JSON
jq -Rsn '
	[inputs
	 | . / "\r\n"
	 | (.[] | select((. | length) > 0) | . / ";") as $input
	 | {"appid": $input[0]|tonumber, "subscriptionlinux": $input[1]}
	]
' < tmux_steam_server_linux.csv > tmux_steam_server_linux.json

pcre2grep -M -o1 -o2 --om-separator=\; 'AppID ([0-9]{1,8})[\s\S]*?release state: (.*)$' tmux_steam_server_output_windows.txt > tmux_steam_server_windows.csv

# convert the CSV to JSON
jq -Rsn '
	[inputs
	 | . / "\r\n"
	 | (.[] | select((. | length) > 0) | . / ";") as $input
	 | {"appid": $input[0]|tonumber, "subscriptionwindows": $input[1]}
	]
' < tmux_steam_server_windows.csv > tmux_steam_server_windows.json

echo "Adding Linux compatibility information."
jq '[.[] | .linux = (.subscriptionlinux | contains("Invalid Platform") | not ) and (.subscriptionlinux | contains("unknown") | not )]' < tmux_steam_server_linux.json > tmux_steam_server_linux.json$$
mv tmux_steam_server_linux.json$$ tmux_steam_server_linux.json

echo "Adding Windows compatibility information."
jq '[.[] | .windows = (.subscriptionwindows | contains("Invalid Platform") | not ) and (.subscriptionwindows | contains("unknown") | not )]' < tmux_steam_server_windows.json > tmux_steam_server_windows.json$$
mv tmux_steam_server_windows.json$$ tmux_steam_server_windows.json

echo "Merging information."
jq -s '[ .[0] + .[1] + .[2] | group_by(.appid)[] | add]' steamcmd_appid_servers.json tmux_steam_server_linux.json tmux_steam_server_windows.json > steamcmd_appid_servers.json$$
mv steamcmd_appid_servers.json$$ steamcmd_appid_servers.json

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

echo "exit"
exit
