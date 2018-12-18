#!/bin/bash



# jq debe estár instalado para esto, recomiendo usar `scoop install jq`

db_file="data_to_release.json"
all_json=$(jq -c . $db_file)
files_length=$(echo $all_json | jq .file_names | jq length )

execAllRelease()
{


# aqui parseamos json.body para enviarlo en la release
text=$(echo $all_json | jq .body )
# aqui tomamos la rama
branch=$(git rev-parse --abbrev-ref HEAD)
# aque leemos el token que está en el json para la auth de la release
token=$(echo $all_json | jq -r .token )
#aqui tomamos el origin para la release, siendo ORIGIN el link repositorio
#repo_full_name=$(git config --get remote.origin.url)
repo_full_name=$(echo $all_json | jq -r .github_repo )
version=$(jq -r .version "package.json" )
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


# git config --global github.token YOUR_TOKEN

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


#aqui hago el POST de la release donde envio el JSON
echo''
echo "========== find here ==========="  
echo "https://api.github.com/repos/$user/$repo/releases"
echo "Insert release ID:"
read -r id
echo "================================"  

echo ''

path1=$(curl --request PATCH --data "$(generate_post_data)" "https://api.github.com/repos/$user/$repo/releases/$id?access_token=$token")

echo "Release edited $version for repo: $repo_full_name branch: $branch"
echo ''
arr=$(curl -X GET "https://api.github.com/repos/$user/$repo/releases" -s | jq -c [.[].assets[].id])
files_length=$(echo $arr | jq . | jq length )

i=0
# por si falla el tamaño y es necesario una suma o resta
max=$(($files_length+0))
# este ciclo se repite según el número de assest que se vayan a subir
while [ $i -lt $max ]
do
  item=$(echo $arr | jq .[$i] )
    echo '' #salto de linea
    echo "Please wait... deleting: $item"
    GH_ASSET="https://api.github.com/repos/$user/$repo/releases/assets/$item?access_token=$token" 
    curl --request DELETE "$GH_ASSET"
    true $(( i++ ))
done
files_length=$(echo $all_json | jq -c ".file_names" | jq length )
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
  	p_req=$(curl --request PATCH --data-binary @"$filename" -H "Authorization: token $token" -H "Content-Type: application/octet-stream" $GH_ASSET | jq -r 'if .state == "uploaded" then "Uploaded: √ ok" else "ERROR" end')    
  	echo ''
  	echo $p_req
    true $(( i++ ))
done

}



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


