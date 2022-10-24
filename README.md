# SteamCMD AppID List Servers

<p align="center">
  <a href="https://developer.valvesoftware.com/wiki/SteamCMD"><img src="https://user-images.githubusercontent.com/4478206/197542699-ae13797a-78bb-4f37-81c2-d4880fd7709f.jpg" alt="SteamCMD"></a>
<br>
</p>
<p align="center">
<a href="https://github.com/dgibbs64/SteamCMD-AppID-List-Servers/actions"><img alt="GitHub Workflow Status" src="https://img.shields.io/github/workflow/status/dgibbs64/SteamCMD-AppID-List-Servers/Generate%20Output?logo=github&style=flat-square&logoColor=white"></a>
<a href="https://www.codacy.com/gh/dgibbs64/SteamCMD-AppID-List-Servers/dashboard"><img src="https://img.shields.io/codacy/grade/61b87c56e64f46a0a29df385dd7e5c60?style=flat-square&logo=codacy&logoColor=white" alt="Codacy grade"></a>
<a href="https://developer.valvesoftware.com/wiki/SteamCMD"><img src="https://img.shields.io/badge/SteamCMD-000000?style=flat-square&logo=Steam&logoColor=white" alt="SteamCMD"></a>
<a href="https://www.gnu.org/software/bash/"><img src="https://img.shields.io/badge/Made with BASH-1f425f?style=flat-square&logo=gnu bash&logoColor=white" alt="SteamCMD"></a>
<a href="https://github.com/dgibbs64/SteamCMD-AppID-List-Servers/blob/main/LICENSE"><img src="https://img.shields.io/github/license/dgibbs64/SteamCMD-AppID-List-Servers?style=flat-square" alt="MIT License"></a>
</p>

## Description

This repository stores every dedicated server `AppID` and its name available on Steam as `json`, `CSV` and `MD` table by grabbing the info from the SteamAPI and filtering for the word `server`.

[steamcmd_appid_servers.json](https://api.steampowered.com/ISteamApps/GetAppList/v2/)

## List

You can get the output without using the script.

[steamcmd_appid_servers.json](https://github.com/dgibbs64/SteamCMD-AppID-List-Servers/blob/master/steamcmd_appid_servers.json)

[steamcmd_appid_servers.csv](https://github.com/dgibbs64/SteamCMD-AppID-List-Servers/blob/master/steamcmd_appid_servers.csv)

[steamcmd_appid_servers.md](https://github.com/dgibbs64/SteamCMD-AppID-List-Servers/blob/master/steamcmd_appid_servers.md)

### Linux Only

A list of linux supported servers are listed below

[steamcmd_appid_servers_linux.json](https://github.com/dgibbs64/SteamCMD-AppID-List-Servers/blob/master/steamcmd_appid_servers_linux.json)

[steamcmd_appid_servers_linux.csv](https://github.com/dgibbs64/SteamCMD-AppID-List-Servers/blob/master/steamcmd_appid_servers_linux.csv)

[steamcmd_appid_servers_linux.md](https://github.com/dgibbs64/SteamCMD-AppID-List-Servers/blob/master/steamcmd_appid_servers_linux.md)

> GitHub Action checks daily for updates and posts them to this repository. So this list will always be up-to-date.

## Usage

Simply download the script and run it.

```bash
wget https://raw.githubusercontent.com/dgibbs64/SteamCMD-AppID-List-Servers/master/steamcmd_appid_server.sh
chmod +x steamcmd_appid_server.sh
./steamcmd_appid_server.sh
```

## SteamDB

A list of server packages can also be seen using SteamDB
[SteamDB](https://steamdb.info/search/?a=app&q=server)
