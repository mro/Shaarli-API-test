#!/bin/sh
cd "$(dirname "$0")/.."

entries=-1
entries=$(curl --silent "$BASE_URL/?do=atom" | xmllint --encode utf8 --format - | grep --count "<entry>")

[ $entries -eq 1 ] || { echo "expected exactly one <entry>" && exit 1 ; }
