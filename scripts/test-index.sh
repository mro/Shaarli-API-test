#!/bin/sh
cd "$(dirname "$0")/.."

curl --silent "$BASE_URL/" | xmllint --html --encode utf8 --format -
exit $?
