#!/bin/sh
set -e

ctr=$(buildah from wine:3.0)

WINEPREFIX=/opt/gphotos-uploader
buildah config \
	--env WINEPREFIX=$WINEPREFIX \
	--env WINEDEBUG=-all \
	$ctr

buildah add $ctr "https://dl.google.com/drive/gsync_enterprise64.msi" /tmp/
buildah copy $ctr user_setup.config /config/user_default/
buildah run $ctr sh -c '
	mkdir -p "$WINEPREFIX/drive_c/users/root/Local Settings/Application Data/Google"
	ln -s /config "$WINEPREFIX/drive_c/users/root/Local Settings/Application Data/Google/Drive"
	mkdir -p /upload
	ln -s /upload "$WINEPREFIX/drive_c/upload"'
buildah run $ctr sh -c '
	wine64 msiexec /i /tmp/gsync_enterprise64.msi || exit $?
	# terminate wineserver etc to allow everything to save state
	while pkill -P 1; do
		sleep 0.1
	done'
buildah run $ctr rm -f /tmp/gsync_enterprise64.msi # /tmp/wine_gecko-2.47-x86_64.msi

buildah copy $ctr oauth-proxy-url-handler.sh /usr/local/bin/oauth-proxy-url-handler
buildah run $ctr sed -i \
	-e '/\[Software\\\\Classes\\\\http\(s\)\?\\\\shell\\\\open\\\\command\]/,/^$/ s/winebrowser\.exe\\" -nohome"/winebrowser.exe\\" \\"%1\\""/' \
	-e '/\[Software\\\\Classes\\\\http\(s\)\?\\\\shell\\\\open\\\\ddeexec/,/^$/ d' \
	"$WINEPREFIX/system.reg"
buildah run $ctr sh -c 'cat >> "$WINEPREFIX/user.reg"' <<-"E_REGTEXT"
	[Software\\Wine\\WineBrowser] 1564726662
	#time=1d548f9fe2e6018
	"Browsers"="oauth-proxy-url-handler"
E_REGTEXT

buildah config \
	--cmd "wine64 '$WINEPREFIX/drive_c/Program Files/Google/Drive/googledrivesync.exe'" \
	--workingdir /config \
	--volume /config \
	$ctr

img=$(buildah commit --rm $ctr gphotos-uploader)
