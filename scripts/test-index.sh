#!/bin/sh
cd "$(dirname "$0")/.."

curl --location "$BASE_URL/" | xmllint --encode utf8 --format -
exit $?
