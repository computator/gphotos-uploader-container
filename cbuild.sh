#!/bin/sh
set -e

ctr=$(buildah from wine:3.0)

buildah config --env WINEPREFIX=/opt/gphotos-uploader $ctr

buildah add $ctr "https://dl.google.com/drive/gsync_enterprise64.msi" /tmp/
buildah add $ctr "http://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86_64.msi" /tmp/
buildah run $ctr sh -c '
	mkdir -p "$WINEPREFIX/drive_c/users/root/Local Settings/Application Data/Google"
	ln -s /config "$WINEPREFIX/drive_c/users/root/Local Settings/Application Data/Google/Drive"
	mkdir -p /config/user_default
	cat > /config/user_default/user_setup.config' <<-"E_GSYNC_CONFIG"
		[Computers]
		desktop_enabled: False
		documents_enabled: False
		pictures_enabled: False
		folders: /upload
		# if high quality is disabled it means upload in original quality
		high_quality_enabled: False
		always_show_in_photos: True
		usb_sync_enabled: False
		ignore_extensions: ext1, ext2, ext3
		# Delete mode can be: ALWAYS_SYNC_DELETES, ASK, NEVER_SYNC_DELETES
		delete_mode: NEVER_SYNC_DELETES

		[MyDrive]
		my_drive_enabled: False
		# folder: /path/to/google_drive

		[Settings]
		autolaunch: True
		show_overlays: False

		[Network]
		# download_bandwidth: 100
		# upload_bandwidth: 200
		# use_direct_connection: False
	E_GSYNC_CONFIG
buildah run $ctr sh -c '
	wine64 msiexec /i /tmp/wine_gecko-2.47-x86_64.msi || exit $?
	wine64 msiexec /i /tmp/gsync_enterprise64.msi || exit $?
	while pkill -P 1; do
		sleep 0.1
	done'
buildah run $ctr rm -f /tmp/gsync_enterprise64.msi /tmp/wine_gecko-2.47-x86_64.msi

buildah config \
	--cmd 'wine64 "/opt/gphotos-uploader/drive_c/Program Files/Google/Drive/googledrivesync.exe"' \
	--workingdir /config \
	--volume /config \
	--volume /upload \
	--env WINEDEBUG=-all \
	$ctr

img=$(buildah commit --rm $ctr gphotos-uploader)