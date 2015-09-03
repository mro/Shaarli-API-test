#!/bin/sh
cd "$(dirname "$0")/.."

if [[ ""="$SHAARLI_SRC" ]] ; then
	echo "How strange - where is the environment." 1>&2
	SHAARLI_SRC=https://github.com/sebsauvage/Shaarli/archive/master.tar.gz
fi

curl --output tarball.tar.gz --url "$(SHAARLI_SRC)" || { echo "ouch" && exit 1 ; }

tar -xzf tarball.tar.gz || { echo "ouch" && exit 2 ; }

ls -l index.php || { echo "ouch" && exit 3 ; }
