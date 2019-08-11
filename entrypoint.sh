#!/bin/sh
set -e

REGFILE="/config/drive_config.reg"

pid=

handle_exit() {
	[ -z "$pid" ] || kill $pid || true
	sleep 1
	while pkill -f 'googledrivesync\.exe|GoogleUpdate'; do sleep 1; done
	while pkill -fi 'C:\\|wineserver'; do sleep 0.2; done
}

load_reg() {
	[ -f "$REGFILE" ] || return 0
	sed -i -e '
			/\[Software\\\\Google\\\\Drive\]/,/^$/ {
				/^$/ r '"$REGFILE"'
				d
			}
		' "$WINEPREFIX/user.reg"
}

save_reg() {
	sed -e '/\[Software\\\\Google\\\\Drive\]/,/^$/! d' \
		"$WINEPREFIX/user.reg" > "$REGFILE"
}

if [ "$1" = 'googledrivesync' ]; then
	trap handle_exit INT TERM

	load_reg

	fb_pid=
	if [ -z "$DISPLAY" ] && ! mountpoint -q /tmp/.X11-unix; then
		export DISPLAY=:11
		Xvfb $DISPLAY &
		fb_pid=$!
	fi

	wine64 "$WINEPREFIX/drive_c/Program Files/Google/Drive/googledrivesync.exe" &
	pid=$!
	tail --follow=name --retry --lines=0 --pid $pid /config/user_default/sync_log.log 2> /dev/null &

	wait $pid && rv=$? || rv=$? # saves exit code in rv after waiting

	[ -n "$fb_pid" ] && kill $fb_pid 2>/dev/null || true
	save_reg

	exit $rv
fi

exec "$@"