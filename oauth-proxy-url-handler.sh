#!/bin/sh
# stdout is redirected to /dev/null so change it to
# the same as stderr which is the real output
exec >&2
# example oauth url: https://accounts.google.com/o/oauth2/v2/auth?code_challenge=SqdZWX-9IJ0Bh00vSnXWpbyg1iy5GORTGlmqDbKf1vM&code_challenge_method=S256&client_id=645529619299.apps.googleusercontent.com&redirect_uri=http%3A%2F%2Flocalhost%3A41869&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdrive+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fgoogletalk+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fpeopleapi.readonly&access_type=offline&response_type=code
if expr match "$1" '.*google\.com/\S*/oauth\S*/auth?' > /dev/null; then
	auth_url="$1"
	int_port=$(expr match "$auth_url" '.*redirect_uri=http%3A%2F%2Flocalhost%3A\([0-9]\+\).*')
	echo "Found OAuth listening port ${int_port}"
	echo "Auth URL: ${auth_url}"
else
	echo "Got invalid OAuth URL:" "$1"
	exit 1
fi