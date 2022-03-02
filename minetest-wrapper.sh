#!/bin/bash

# Main loop
while true ; do
	echo -e "\n\n-- Separator --\n\n" >> /tmp/minetest.stderr
	minetestserver $@ 2>&1 | tee -a /tmp/minetest.stderr
	echo "Minetest server crashed! See error logs at debug.txt and /tmp/minetest.stderr"
	echo "Restarting in 5s ..."
	sleep 5
done
