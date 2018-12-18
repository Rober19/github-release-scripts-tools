#!/bin/bash



execAllRelease()
{
# aqui aumento la version de npm
npm version patch -f
# aqui la leemos para mandarla a la release
PACKAGE_VERSION=$(cat ./package.json \
  | grep version \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]')

 version=$PACKAGE_VERSION 

# aqui parseamos json.body para enviarlo en la release
 text=$(echo $all_json | jq .body )
# aqui tomamos la rama
branch=$(git rev-parse --abbrev-ref HEAD)
# aque leemos el token que está en el json para la auth de la release
token=$(echo $all_json | jq -r .token )
echo $token

#aqui tomamos el origin para la release, siendo ORIGIN el link repositorio
#repo_full_name=$(git config --get remote.origin.url)
repo_full_name=$(echo $all_json | jq -r .github_repo )
url=$repo_full_name
# aqui parseamos el link del repositorio, sea http o ssh (recomiendo usar ssh)
re="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+).git$"
if [[ $url =~ $re ]]; then    
    protocol=${BASH_REMATCH[1]}
    separator=${BASH_REMATCH[2]}
    hostname=${BASH_REMATCH[3]}
    user=${BASH_REMATCH[4]}
    repo=${BASH_REMATCH[5]}
fi

generate_post_data()
{
  cat <<EOF
{
  "tag_name": "$version",
  "target_commitish": "$branch",
  "name": "$version",
  "body": $text,
  "draft": false,
  "prerelease": false
}
EOF
} 

echo "Create release $version for repo: $repo_full_name branch: $branch"
#aqui hago el POST de la release donde envio el JSON
id=$(curl --data "$(generate_post_data)" "https://api.github.com/repos/$user/$repo/releases?access_token=$token" | jq -r '.id')
#echo "the id is: $id"
i=0
# por si falla el tamaño y es necesario una suma o resta
max=$(($files_length+0))
# este ciclo se repite según el número de assest que se vayan a subir
while [ $i -lt $max ]
do
    filename=$(echo $all_json | jq -r ".file_names[$i]" )
    echo ''
    echo ''
    echo "Please wait... uploading: $filename"
    GH_ASSET="https://uploads.github.com/repos/$user/$repo/releases/$id/assets?name=$(basename $filename)"   
  	p_req=$(curl --data-binary @"$filename" -H "Authorization: token $token" -H "Content-Type: application/octet-stream" $GH_ASSET | jq -r 'if .state == "uploaded" then "Uploaded: √ ok" else "ERROR" end')    
  	echo ''
  	echo $p_req
    true $(( i++ ))
done

}

db_file="data_to_release.json"
all_json=$(jq -c . $db_file)
files_length=$(echo $all_json | jq .file_names | jq length )

if [ -e "$db_file" ]
then
    execAllRelease 
  echo ''
  echo '=================================='
  read -r 1 -p "Press any key to continue..."
    exit 0
else
  echo ''
    echo "$db_file not found"
    echo ''
    echo '=================================='
    read -r 1 -p "Press any key to continue..."
    exit 0
fi


# me guié de esto
# https://api.github.com/repos/Microsoft/Git-Credential-Manager-for-Windows/releases/latest


