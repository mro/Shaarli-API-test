#!/bin/sh
cd "$(dirname "$0")/.."

# Download the tarball...
curl --location --output tarball.tar.gz --url "$SHAARLI_SRC" || { echo "ouch" && exit 1 ; }

# ...and unpack into directory 'Shaarli'...
tar -xzf tarball.tar.gz || { echo "ouch" && exit 2 ; }
mv Shaarli-* Shaarli && rm tarball.tar.gz

ls -l Shaarli
ls -l Shaarli/index.php || { echo "ouch" && exit 3 ; }
