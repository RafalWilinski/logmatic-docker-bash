#!/bin/bash
apiKey=""
host="api.logmatic.io"
port="10514"
forwardEvents=false
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

formatEvent() {
  if [ "$forwardEvents" = true ] ; then
    echo "$apiKey type=$2 event=$3 id=$4" >&3
  fi
}

formatStat() {
  echo "$apiKey id=$1 cpu=$2 memUsage=$3 memAvail=$6 netIn=$9"
  echo "$apiKey id=$1 cpu=$2 memUsage=$3 memAvail=$6 netIn=$9" >&3
}

startFwd() {
  echo "Forwarding logs from $1"
  echo $1 | xargs docker logs --follow --details | formatMsg $1 $2 $3 &
}

while getopts 'a:h:p:s:e' flag; do
  case "${flag}" in 
    a) apiKey="${OPTARG}" ;;
    h) host="${OPTARG}" ;;
    p) port="${OPTARG}" ;;
    e) forwardEvents=true ;;
    s) statsRefreshInterval="${OPTARG}" ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

if [ -z "$apiKey" ]
then
  echo "API Key was not provided. Please supply it with an '-a' flag."
  exit 1;
else 
  echo "Starting docker-logmatic..."
fi

# Open socket to Logmatic.io under file descriptor #3
exec 3<>/dev/tcp/$host/$port

# On start, catch all running containers and start log forwaring
docker ps --format '{{.ID}} {{.Names}} {{.Image}}' | while read line; do
  startFwd $line
done

# Gather stats every N seconds and forward 
while :
do
  docker stats --no-stream | tail -n +2 | while read line; do
    echo $line;
    formatStat $line
  done

  sleep $statsRefreshInterval
done &

# Forward docker events 
docker events | while read line; do
  formatEvent $line
  id=$(echo $line | cut -d ' ' -f 4)
  event=$(echo $line | cut -d ' ' -f 3)
  
  # Discover any new containers and also forward logs from them
  if [ "$event" = "start" ] 
  then
    echo "New container detected!"
    docker ps -f "id=$id" --format '{{.ID}} {{.Names}} {{.Image}}' | while read line; do
      startFwd $line
    done
  fi
done