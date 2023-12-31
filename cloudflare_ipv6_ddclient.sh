#!/bin/bash

INTERFACE="enp3s0f0"
API_KEY=""
EMAIL=""
ZONE="example.com"
NAMES="sub"

source ~/.config/cloudflare_ipv6_ddclient/config

NAME_LIST=(${NAMES//,/ })

IP=`ip -o a |\
    grep ${INTERFACE} |\
    grep "inet6" |\
    grep "scope global dynamic" |\
    awk '{print $4}' |\
    sed -e 's/\(.*\)\/64/\1/'`

echo "current ip: ${IP}"

ZONE_ID=`curl -H "x-Auth-Key: ${API_KEY}" \
              -H "x-Auth-Email: ${EMAIL}" \
              "https://api.cloudflare.com/client/v4/zones?name=${ZONE}" |\
	     jq -r .result[0].id`

echo "success to fetch zone id: ${ZONE_ID}"

for NAME in "${NAME_LIST[@]}"
do

DOMAIN=${NAME}'.'${ZONE}

DOMAIN_ID=`curl -H "x-Auth-Key: ${API_KEY}" \
	            -H "x-Auth-Email: ${EMAIL}" \
		        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=AAAA&name=${DOMAIN}" |\
           jq -r .result[0].id`

echo "success to fetch domain id: ${DOMAIN_ID}"

generate_body() {
    cat << EOS
{
    "type": "AAAA",
    "name": "$NAME",
    "content": "$IP"
}
EOS
}

curl -X PATCH \
     -H "x-Auth-Key: ${API_KEY}" \
     -H "x-Auth-Email: ${EMAIL}" \
     -H "Content-Type: application/json" \
     -d "$(generate_body)" \
     "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DOMAIN_ID}"

echo "success to update address"
done
