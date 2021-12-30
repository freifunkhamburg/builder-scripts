#!/bin/bash -e

BASEPATH=~/firmware

cat <<EOF
This script modifies the stable.manifest and beta.manifest in each firmware directory and updates
the branch, date and priority information. Signatures will be removed as they become invalid due to the changes.
It will ask you which firmware you want modify.

EOF

cd $BASEPATH
firmware=(v*/)
echo Available firmware versions in $(pwd):
for i in ${!firmware[*]}; do
	echo $i. ${firmware[$i]}
done
read -p 'Enter the number of the firmware you wish to update: ' fw
firmware=${firmware[$fw]}
echo Selected firmware: ${firmware}

echo
echo Manifest to be modified:
m=${BASEPATH}/${firmware}/stable/images/sysupgrade/stable.manifest
echo "####### Manifest: ${m}"
head -3 $m

echo
echo Press enter if you want to use the manifest listed above. To abort, hit Ctrl+C.
read -sr confirm
echo

valuesok=n
while [ "${valuesok}" != "y" ]; do
	echo -n 'Please enter the new priority (default 7): '
	read -r prio
	echo
	prio=${prio:-7}

	d=${d:-$(date '+%Y-%m-%d %H:%M:%S%:z')}
	echo 'The date will be interpreted by "date", so you can use something like "tuesday"'
	echo -n "Please enter the new date (default: $d): "
	read -r newd
	d="$(date --date="${newd:-${d:-now}}" '+%Y-%m-%d %H:%M:%S%:z')"

	cat <<-EOF
		New settings:
		Priority: $prio
		Date: $d
	EOF
	echo
	echo 'Is this correct? [yn] '
	read -r valuesok
done

echo
echo Updating manifest...
# Use the stable manifest as source...
src="$(cat ${BASEPATH}/${firmware}/stable/images/sysupgrade/stable.manifest)"
for branch in beta stable; do
	m=${BASEPATH}/${firmware}/stable/images/sysupgrade/${branch}.manifest
	echo "####### Manifest: ${m}"
	awk -v "branch=${branch}" -v "d=${d}" -v "prio=${prio}" '/^BRANCH=/ {print "BRANCH=" branch; next} /^DATE=/ {print "DATE=" d; next} /^PRIORITY=/ {print "PRIORITY=" prio; next} /^---/ {exit} {print}' <<< "${src}" > "${m}"
done
