#!/bin/sh
cd "$(dirname "$0")/.."

curl --location --output tarball.tar.gz --url "$SHAARLI_SRC" || { echo "ouch" && exit 1 ; }

tar -xzf tarball.tar.gz || { echo "ouch" && exit 2 ; }
mv Shaarli-*/* . && rm tarball.tar.gz && rmdir Shaarli-*

ls -l
ls -l index.php || { echo "ouch" && exit 3 ; }
