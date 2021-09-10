#!/bin/bash

# Main loop
while true ; do
	minetestserver $@
	echo "Minetest server crashed! See error logs at debug.txt"
	echo "Restarting in 5s ..."
	sleep 5
done
