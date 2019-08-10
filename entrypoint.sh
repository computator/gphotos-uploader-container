#!/bin/sh
set -e

handle_exit() {
	pkill -P $$
}

if [ "$1" = 'googledrivesync' ]; then
	trap handle_exit INT TERM
	wine64 "$WINEPREFIX/drive_c/Program Files/Google/Drive/googledrivesync.exe" &
	wait $!
	exit $?
fi

exec "$@"