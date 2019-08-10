#!/bin/sh
set -e

pid=

handle_exit() {
	# kill children of pid if set, otherwise all children
	pkill -P ${!:-$$}
}

if [ "$1" = 'googledrivesync' ]; then
	trap handle_exit INT TERM
	wine64 "$WINEPREFIX/drive_c/Program Files/Google/Drive/googledrivesync.exe" &
	pid=$!
	tail --follow=name --retry --lines=0 --pid $pid /config/user_default/sync_log.log 2> /dev/null &
	wait $pid
	exit $?
fi

exec "$@"