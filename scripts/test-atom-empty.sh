#!/bin/sh
cd "$(dirname "$0")/.."

entries=-1
entries=$(curl --silent "$BASE_URL/?do=atom" | xmllint --encode utf8 --format - | grep --count "<entry>")

if [ $entries -eq 1 ] ; then
  exit 0
else
  exit 1
fi
