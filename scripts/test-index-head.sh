#!/bin/sh
cd "$(dirname "$0")/.."

curl --location --head "$BASE_URL/index.php"
exit $?
