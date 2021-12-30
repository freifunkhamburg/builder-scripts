#!/bin/bash -e

if [ -z "$1" ]; then
	echo Usage: $0 '<MANIFEST>' >&2
	exit 1
fi

echo
echo Starting the signature process.
read -sp 'Please enter your private key (hidden) and press enter: ' privkey
echo

echo
echo Signing manifest "$1" ...
# check if the separator is already in the file
if ! fgrep -q -- --- "$1"; then
	echo --- >> "$1"
fi
ecdsasign <( awk '/^BRANCH/,/^---/' "$1" | egrep -v ^--- ) <<< "$privkey" >> "$1"
echo 'Last 10 lines of the signed manifest:'
tail -10 "$1"
