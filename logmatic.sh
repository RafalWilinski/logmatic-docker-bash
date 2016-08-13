#!/bin/bash
apiKey=""
host="api.logmatic.io"
port="10514"
statsRefreshInterval=10

###
# WARNING!
# In order to make parsing work, first you have to go to your Logmatic.console
# Settings -> Enrichment & Parsing -> ENABLE Key/Value 
###

formatMsg() {
  while read data; do
    echo "$apiKey id=$1 name=$2 image=$3 message=\"$data\"" >&3
  done;
}

startFwd() {
  echo "Forwarding logs from $1"
  echo $1 | xargs docker logs --follow --details | formatMsg $1 $2 $3 &
}

while getopts 'a:h:p:' flag; do
  case "${flag}" in 
    a) apiKey="${OPTARG}" ;;
    h) host="${OPTARG}" ;;
    p) port="${OPTARG}" ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

if [ -z "$apiKey" ]
then
  echo "API Key was not provided. Please supply it with an '-a' flag."
  exit 1;
fi

# Open socket to Logmatic.io under file descriptor #3
exec 3<>/dev/tcp/$host/$port

# On start, catch all running containers and start log forwaring
docker ps --format '{{.ID}} {{.Names}} {{.Image}}' | while read line; do
  startFwd $line
done

# Discover any new containers and also forward logs from them
docker events --filter event=start | while read line; do
  id=$(echo $line | cut -d ' ' -f 4)
  echo "Starting $id"

  docker ps -f "id=$id" --format '{{.ID}} {{.Names}} {{.Image}}' | while read line; do
    startFwd $line
  done
done

