#!/bin/bash -e

LOCAL_BASE="${HOME}/firmware/update-mirror"

show_usage() {
cat <<EOF
This script adds firmware to the update-mirror. Note that this script will replace an already existing version if
it has the same version number.
Usage: $0 [-r] [-n] [-u] <firmware>
	-r	Release the firmware by changing the branch specific link to point to the new firmware
	-n	Set the rsync dry-run flag (WARNING: does not prevent the release link!)
	-u	rsync update-mirror to the update servers. use sync-firmware.sh if you want to do that later.
	firmware: The directory created by the site-ffhh/build.sh script
			for example: /home/gluon/firmware/0.8.5+exp20171028
			Must contain a single subdirectory named stable or experimental.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		-r)
			RELEASE=1
			;;
		-n)
			DRYRUN=--dry-run
			;;
		-u)
			UPLOAD=1
			;;
		*)
			FIRMWARE="$1"
			if [ ! -d "$FIRMWARE" ]; then
				show_usage
				exit 1
			fi
			;;
	esac
	shift
done

if [ ! -d "$FIRMWARE" ]; then
	show_usage
	exit 1
fi

pushd "$FIRMWARE" 2>/dev/null
VERSION="$(basename -- $(pwd -P))"
branch=$(ls | head -1)
pushd "$branch" 2>/dev/null
echo '############################# Updating the local mirror...'
TARGET="${LOCAL_BASE}/multi/archive/${VERSION}"
mkdir -p "${TARGET}"
rsync --verbose --progress --stats --recursive --hard-links --links --perms --times $DRYRUN . "${TARGET}"
if [ "${RELEASE}" == "1" ]; then
	rm -f "${LOCAL_BASE}/multi/${branch}"
	ln -s "archive/${VERSION}" "${LOCAL_BASE}/multi/${branch}"
fi

if [ "${UPLOAD}" == "1" ]; then
	echo '############################# Uploading to servers...'
	rsync --recursive --delete-before --links --hard-links --times --partial --verbose --progress $DRYRUN $EXCLUDES "${LOCAL_BASE}/." ffupdates@srv01.hamburg.freifunk.net:updates/
	rsync --recursive --delete-before --links --hard-links --times --partial --verbose --progress $DRYRUN $EXCLUDES "${LOCAL_BASE}/." ffupdates@srv03.hamburg.freifunk.net:/var/www/updates/
fi
