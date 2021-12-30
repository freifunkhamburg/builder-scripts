#!/bin/bash -e

while [ $# -gt 0 ]; do
	case "$1" in
		-n)
			DRYRUN=--dry-run
			;;
		*)
			echo "Unknown option: $1" >&2
			exit 1
			;;
	esac
	shift
done

echo '############################# Uploading to srv01...'
rsync --recursive --delete-before --links --hard-links --times --partial --verbose --progress $DRYRUN ~/firmware/update-mirror/. ffupdates@srv01.hamburg.freifunk.net:updates/
echo '############################# Uploading to srv03...'
rsync --recursive --delete-before --links --hard-links --times --partial --verbose --progress $DRYRUN ~/firmware/update-mirror/. ffupdates@srv03.hamburg.freifunk.net:/var/www/updates/
