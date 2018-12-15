cmd "/C bat_deploy.bat"
sh new-git-release.sh
read -n 1 -p "Press any key to continue"
exit 0
