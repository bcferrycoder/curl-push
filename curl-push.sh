#!/bin/bash

# this script invokes the Cloud Foundry APIs via curl to push an application

# customization section
STACKATO_HOST=https://api.192.168.0.112.xip.io
USERNAME=jdw
PASSWORD=jdw
APPNAME=java-hello
ZIPFILE=my-app.zip
# end customization section


if [ ! -f "$ZIPFILE" ]
then
    echo "Application zip file required"
    echo "Create a zipfile containing the app and manifest, update ZIPFILE above, and try again"
    exit
fi

echo "######### /uaa/oauth/token"
TOKEN=`curl -s -k -H 'AUTHORIZATION: Basic Y2Y6' -d "username=${USERNAME}&password=${PASSWORD}&grant_type=password" ${STACKATO_HOST}/uaa/oauth/token | jq -r .access_token`
AUTH="Authorization: bearer $TOKEN"

echo "GET SPACE"
export SPACE=`curl -s -k -H "${AUTH}" ${STACKATO_HOST}/v2/spaces| jq -r ".resources[0].metadata.guid"`

echo "GET DOMAIN"
export DOMAIN=`curl -s -k -H "${AUTH}" ${STACKATO_HOST}/v2/spaces/${SPACE}/domains | jq -r ".resources[0].metadata.guid"`
echo "GOT DOMAIN: $DOMAIN"

echo "CREATE APP"
export POST_DATA=$(cat <<EOF
{"disk_quota":2048,"memory": 512,"name":"${APPNAME}","space_guid":"${SPACE}"}
EOF
)
curl -k -X POST -d "${POST_DATA}" -H "${AUTH}" ${STACKATO_HOST}/v2/apps

echo "CREATE ROUTE"
export POST_DATA=$(cat <<EOF
{"domain_guid":"${DOMAIN}","host":"${APPNAME}","space_guid":"${SPACE}"}
EOF
)
curl -k -X POST -d "${POST_DATA}" -H "${AUTH}" ${STACKATO_HOST}/v2/routes

echo "GET ROUTE"
export ROUTE=`curl -s -k -H "${AUTH}" ${STACKATO_HOST}/v2/routes | jq -r ".resources[0].metadata.guid"`
echo "ROUTE: $ROUTE"

echo "GET APP"
export APP=`curl -s -k -H "${AUTH}" ${STACKATO_HOST}/v2/apps | jq -r ".resources[0].metadata.guid"`
echo $APP

echo "ASSOCIATE ROUTE"
curl -k -X PUT -H "${AUTH}" ${STACKATO_HOST}/v2/apps/${APP}/routes/${ROUTE}

echo "UPLOAD BITS"
echo curl -H "Expect:" -0 -include -v -k -X PUT -H "${AUTH}" -F 'resources=[]' -F "application=@${ZIPFILE};type=application/binary" ${STACKATO_HOST}/v2/apps/${APP}/bits
curl -H "Expect:" -0 -include -v -k -X PUT -H "${AUTH}" -F 'resources=[]' -F "application=@${ZIPFILE};type=application/binary" ${STACKATO_HOST}/v2/apps/${APP}/bits

echo "START APP"
curl -v -k -X PUT -d '{"console":true,"state":"STARTED"}' -H "${AUTH}" ${STACKATO_HOST}/v2/apps/${APP}
