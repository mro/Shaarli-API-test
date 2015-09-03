#!/bin/sh
cd "$(dirname "$0")/.."

ls -l
curl --location --output tarball.tar.gz --url "$SHAARLI_SRC" || { echo "ouch" && exit 1 ; }
ls -l

tar -xzf tarball.tar.gz || { echo "ouch" && exit 2 ; }
ls -l
rm tarball.tar.gz

ls -l
ls -l index.php || { echo "ouch" && exit 3 ; }
