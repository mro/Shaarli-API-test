#!/bin/sh
cd "$(dirname "$0")/.."

# Download the tarball...
curl --location --output source.tar.gz --url "$GITHUB_SRC_URL" || { echo "ouch" && exit 1 ; }
