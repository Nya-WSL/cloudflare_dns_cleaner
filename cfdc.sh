#!/bin/bash
###
 # @Author: Nya-WSL
 # Copyright © 2023 by Nya-WSL All Rights Reserved. 
 # @Date: 2023-10-13 16:43:05
 # @LastEditors: 狐日泽
 # @LastEditTime: 2023-10-14 16:49:09
### 

if [ ! "$(command -v jq)" ]
then
  echo "jq is not installed and will be installed soon！" >&2
  if ["$(uname)"=="Darwin"] # macOS
    if [ ! "$(command -v brew)" ]
    then
      echo "Use homebrew to install jq has error, maybe homebrew is not installed?" >&2
      exit 1
    else
      brew install jq
  elif ["$(expr substr $(uname -s) 1 5)"=="Linux"] # GNU/Linux
  then
    source /etc/os-release || source /usr/lib/os-release || panic "system is not supported"
    if [[ $ID == "centos" ]]
    then
      sudo yum insall -y -q jq
    elif [[ $ID == "debian" || $ID == "ubuntu" ]]
    then
      sudo apt-get install -y -q jq
    else
      error "system is not supported"
fi

read -p "Please input your API_TOKEN: " $API_TOKEN
# API_TOKEN=""

read -p "Please input your ZONE_ID: " $ZONE_ID
# ZONE_ID=""

# Initial values
PER_PAGE=100  # Cloudflare API maximum limit per request

while :; do
  RESPONSE=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?per_page=$PER_PAGE&page=1" \
       -H "Authorization: Bearer $API_TOKEN" \
       -H "Content-Type: application/json" \
       -s)

  NUM_RECORDS=$(echo "$RESPONSE" | jq '.result | length')
  if [ "$NUM_RECORDS" -eq 0 ]
  then
    break
  fi

  RECORD_IDS=$(echo "$RESPONSE" | jq -r '.result[].id')

  for RECORD_ID in $RECORD_IDS; do
    curl -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
         -H "Authorization: Bearer $API_TOKEN" \
         -H "Content-Type: application/json" \
         -s
    echo -e "Deleted record ID: $RECORD_ID\n"
  done
done

echo "All records deleted successfully."