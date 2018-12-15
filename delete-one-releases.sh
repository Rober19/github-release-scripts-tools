# cmd "/C bat_deploy.bat"
# sh git-release.sh

db_file="data_to_release.json"
all_json=$(jq -c . $db_file)


deletingAsset()
{

url=$(echo $all_json | jq -r .github_repo )

# aqui parseamos el link del repositorio, sea http o ssh (recomiendo usar ssh)
re="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+).git$"
if [[ $url =~ $re ]]; then    
    protocol=${BASH_REMATCH[1]}
    separator=${BASH_REMATCH[2]}
    hostname=${BASH_REMATCH[3]}
    user=${BASH_REMATCH[4]}
    repo=${BASH_REMATCH[5]}
fi


token=$(echo $all_json | jq -r .token )

echo "Insert release ID:"
read id1
echo "====================="	
echo '' #salto de linea
echo "Please wait... deleting: $id1"
GH_ASSET="https://api.github.com/repos/$user/$repo/releases/$id1?access_token=$token" 
curl -X DELETE "$GH_ASSET"
   

}


if [ -e "$db_file" ]
then
   deletingAsset 
  echo ''
  echo '=================================='
  read -n 1 -p "Press any key to continue..."
    exit 0
else
  echo ''
    echo "$db_file not found"
    echo ''
    echo '=================================='
    read -n 1 -p "Press any key to continue..."
    exit 0
fi
