#!/bin/bash

# Main loop
while true ; do
	echo "-- Separator --" >> /tmp/minetest.stderr
	minetestserver $@ 2>> /tmp/minetest.stderr
	echo "Minetest server crashed! See error logs at debug.txt and /tmp/minetest.stderr"
	echo "Restarting in 5s ..."
	sleep 5
done
