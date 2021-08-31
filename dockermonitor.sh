#!/bin/bash
webhook="webhook"
avatar="https://dockercontainer.it/images/docker-logo.png"
file="/usr/local/root/containers"
if [ ! -e "$file" ] ; then
    echo "can't find $file"
    exit 1
fi

IFS=$'\n'
c=($(cat "$file"))
unset IFS
toskip=()

while sleep 15; do
    echo "LOOP START"
    for container in "${c[@]}"; do
        state=$(docker inspect --format="{{ .State.Running }}" $container 2> /dev/null)
        name=$(docker inspect --format="{{ .Name }}" $container)
	name="${name[@]/\//}"
	if [ $? -eq 1 ]; then
            echo "UNKNOWN - $container does not exist."
        
        elif [[ ! "${toskip[@]}" =~ "$container" && "$state" == "false" ]]; then
            echo "CRITICAL - $container is not running."
	    toskip+=($container)
	    finished=$(docker inspect --format="{{ .State.FinishedAt }}" $container)
	    finished="${finished%.*}"
	    /usr/local/root/discord.sh --webhook-url="$webhook" \
                                       --username "Containers Monitor Police" \
                                       --avatar "$avatar" \
                                       --description "Docker **$name** stopped" \
                                       --text "Docker is stopped since ${finished/T/ }" \
                                       --color 15859712 \
                                       --timestamp
        
        elif [[ "${toskip[@]}" =~ "$container" && "$state" == "true" ]]; then
	    toskip=( "${toskip[@]/$container}" )            
	    started=$(docker inspect --format="{{ .State.StartedAt }}" $container)
	    started="${started%.*}"
	    echo "OK - $container is running. StartedAt: $started"
            /usr/local/root/discord.sh --webhook-url="$webhook" \
                                       --username "Containers Monitor Police" \
                                       --avatar "$avatar" \
                                       --description "Docker **$name** started" \
                                       --text "Docker is running again since ${started/T/ }" \
                                       --color 31488 \
                                       --timestamp
	else
	    continue
        fi
    done
done
