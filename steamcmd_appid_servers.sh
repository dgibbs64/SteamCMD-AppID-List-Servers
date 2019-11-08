#!/bin/bash
# steamcmd_appid_servers.sh
# Author: Daniel Gibbs & Robin Bourne
# Website: http://danielgibbs.co.uk
# Version: 180922
# Description: Saves the complete list of all the appid their names in json and csv.

# Set TMUX_SESSIONS For development
if [ ! -v TMUX_SESSIONS ]; then
	TMUX_SESSIONS=7
fi

# Static variables
rootdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Downloads the source data files for analysis.
download_steam_files() {
		echo "Creating steamcmd_appid.json"
		curl https://api.steampowered.com/ISteamApps/GetAppList/v2/ | jq -r '.' > steamcmd_getapplist.json
}

# Checks for SteamCMD, and installs if it does not exist.
install_steamcmd(){
		echo ""
		echo "Installing SteamCMD."
		cd "${rootdir}" || exit
		mkdir -pv "steamcmd"
		cd "steamcmd" || exit
		if [ ! -f "steamcmd.sh" ]; then
				echo -e "downloading steamcmd_linux.tar.gz...\c"
				wget -N /dev/null http://media.steampowered.com/client/steamcmd_linux.tar.gz 2>&1 | grep -F HTTP | cut -c45-| uniq
				tar --verbose -zxf "steamcmd_linux.tar.gz"
				rm -v "steamcmd_linux.tar.gz"
				chmod +x "steamcmd.sh"
		else
				echo "SteamCMD is already installed."
		fi
		cd "${rootdir}" || exit
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

# check required external variables.
if [ -z "${TMUX_SESSIONS+x}" ]; then
	echo "TMUX_SESSIONS is not set. Please set this variable to allocate the number of TMUX sessions that should be used to query SteamCMD."
	exit 1
fi

# pre-requirements.
install_steamcmd
download_steam_files

echo "Creating steamcmd_appid_servers.json"
cat steamcmd_getapplist.json | jq '[.applist.apps[] | select(.name | contains("server","Server"))]'| jq -s '.[]|sort_by(.appid)' > steamcmd_appid_servers.json

echo "Creating steamcmd_appid_servers.csv"
cat steamcmd_appid_servers.json | jq -r '.[] | [.appid, .name] | @csv' > steamcmd_appid_servers.csv

echo "Creating steamcmd_appid_servers.md"
cat steamcmd_appid_servers.json | md-table > steamcmd_appid_servers.md

# Checks for SteamCMD, and installs if it does not exist.
install_steamcmd(){
		echo ""
		echo "Installing SteamCMD."
		cd "${rootdir}" || exit
		mkdir -pv "steamcmd"
		cd "steamcmd" || exit
		if [ ! -f "steamcmd.sh" ]; then
				echo -e "downloading steamcmd_linux.tar.gz...\c"
				wget -N /dev/null http://media.steampowered.com/client/steamcmd_linux.tar.gz 2>&1 | grep -F HTTP | cut -c45-| uniq
				tar --verbose -zxf "steamcmd_linux.tar.gz"
				rm -v "steamcmd_linux.tar.gz"
				chmod +x "steamcmd.sh"
		else
				echo "SteamCMD is already installed."
		fi
		cd "${rootdir}" || exit
}



echo "exit"
exit
