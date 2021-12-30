#!/bin/bash

[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :

set -euo pipefail

# Low priority for cpu and disk...
renice -n 19 -p $$
ionice -c 3 -p $$

date=$(date +%Y%m%d-%H%M)

# Redirect output if stdin not on terminal
if [ ! -t 0 ]; then
	PIPETMP=$(mktemp -d)
	mkfifo --mode=600 "${PIPETMP}/pipe"
	gzip < "${PIPETMP}/pipe" > "$HOME/firmware/master.log-${date}.txt.gz" &
	exec > "${PIPETMP}/pipe" 2>&1
	rm "${PIPETMP}/pipe"
	rmdir "${PIPETMP}"
fi
set -x

cd "$HOME/build"
[ -e master ] && mv master master.old
rm -rf master.old & disown

mkdir master
cd master

git clone -b master https://github.com/freifunk-gluon/gluon.git
git clone -b master https://github.com/freifunkhamburg/site-ffhh.git

# Set a decent GLUON_RELEASE and force the GLUON_BRANCH to experimental
sed -i -e 's/.*GLUON_BRANCH=.*/GLUON_BRANCH=experimental/' -e "s/.*GLUON_RELEASE=.*/GLUON_RELEASE=master~$(date +%Y%m%d)/" site-ffhh/build.conf
# Make sure that master firmware uses a different SSID to ease testing
sed -i -e 's/ssid = "hamburg.freifunk.net",/ssid = "master.hamburg.freifunk.net",/' site-ffhh/domains/ffhh_*.conf

cd site-ffhh
rc=0
time bash -x ./build.sh -g ../gluon -a -b -s "$HOME/nightly.secret" || rc=$?
echo Return code: $rc

. ./build.conf

if [ "${rc}" -gt 0 ]; then
	echo "Build failed, moving output to ${GLUON_RELEASE}.failed"
	mv "${HOME}/firmware/${GLUON_RELEASE}"* "${HOME}/firmware/${GLUON_RELEASE}.failed"
	exit $rc
fi
