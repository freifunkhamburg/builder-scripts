#!/bin/bash -e

BASEPATH=~/firmware

cat <<EOF
This script is intended to make signing stable firmwares easier.
It will ask you which firmware you want to sign and will ask you for your private key.

EOF

cd $BASEPATH
firmware=(v*/)
echo Available firmware versions in $(pwd):
for i in ${!firmware[*]}; do
	echo $i. ${firmware[$i]}
done
read -p 'Enter the number of the firmware you wish to sign: ' fw
firmware=${firmware[$fw]}
echo Selected firmware: ${firmware}

echo
echo Manifests to be signed:
for betastable in beta stable; do
	m=${BASEPATH}/${firmware}/stable/images/sysupgrade/${betastable}.manifest
	echo "####### Manifest: ${m}"
	if ! head -3 $m; then
		echo ERROR: no beta.manifest, try update_manifests.sh first.
		exit 1
	fi
done

echo
echo Press enter if you want to sign the manifests listed above. To abort, hit Ctrl+C.
read -r confirm

echo
echo Starting the signature process.
read -sp 'Please enter your private key (hidden) and press enter: ' privkey
echo

echo
echo Signing manifests...
for betastable in beta stable; do
	m=${BASEPATH}/${firmware}/stable/images/sysupgrade/${betastable}.manifest
	echo "####### Manifest: ${m}"
	# check if the separator is already in the file
	if ! fgrep -q -- --- $m; then
		echo --- >> $m
	fi
	# generate the signature
	ecdsasign <( awk '/^BRANCH/,/^---/' $m | egrep -v ^--- ) <<< "$privkey" >> $m
done
