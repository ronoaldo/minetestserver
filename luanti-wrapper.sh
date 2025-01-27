#!/bin/bash

MINETEST_STDERR_FILE=${MINETEST_STDERR_FILE:-/tmp/minetest.stderr}

# Main loop
{
while true ; do
	echo -e "\n\n-- Separator --\n\n" >> "${MINETEST_STDERR_FILE}"
	luantiserver "$@"
	RET="$?"
	echo "${RET}" > /tmp/status
	if [ "${NO_LOOP}" == "true" ]; then
		echo "Exiting (${RET})..."
		break
	fi

	echo "Minetest server crashed! See error logs at debug.txt and ${MINETEST_STDERR_FILE}"
	echo "Restarting in 10s ..."
	sleep 10
done
} 2>&1 | tee -a "${MINETEST_STDERR_FILE}"

RET="$(cat /tmp/status || echo 0)"
exit "${RET}"
