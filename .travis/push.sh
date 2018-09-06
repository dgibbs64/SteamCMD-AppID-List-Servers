#!/bin/sh

git config --global user.email "me@danielgibbs.co.uk"
git config --global user.name "dgibbs64"

git remote set-url origin https://dgibbs64:${GH_TOKEN}@github.com/dgibbs64/SteamCMD-AppID-List-Servers.git

git checkout ${TRAVIS_BRANCH}
git add . steamcmd_appid_servers.json
git add . steamcmd_appid_servers.csv
git add . steamcmd_appid_servers.md
git commit --message "Travis build: $TRAVIS_BUILD_NUMBER"


git push --set-upstream origin $(date +%Y-%m-%d)
