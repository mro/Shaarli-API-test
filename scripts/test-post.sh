#!/bin/sh
#
#  Copyright (c) 2015 Marcus Rohrmoser http://mro.name/me. All rights reserved.
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
cd "$(dirname "$0")"

# http://stackoverflow.com/a/10797966
urlencode() {
  local data
  if [ $# != 1 ]; then
    echo "Usage: $0 string-to-urlencode"
    return 1
  fi
  data="$(curl -s -o /dev/null -w %{url_effective} --get --data-urlencode "$1" "")"
  if [ $? != 3 ]; then
    echo "Unexpected error" 1>&2
    return 2
  fi
  echo "${data##/?}"
  return 0
}

[ "$USERNAME" != "" ] || { echo "How strange, USERNAME is unset." && exit 1 ; }
[ "$PASSWORD" != "" ] || { echo "How strange, PASSWORD is unset." && exit 1 ; }
[ "$BASE_URL" != "" ] || { echo "How strange, BASE_URL is unset." && exit 1 ; }

# check pre-condition - there's already 1 public entry in the ATOM feed:
entries=-1
entries=$(curl --silent "$BASE_URL/?do=atom" | xmllint --encode utf8 --format - | grep --count "<entry>")
[ $entries -eq 1 ] || { echo "expected exactly one <entry>, found $entries" && exit 1 ; }

# fetch token to login and add a new link:
params="post=$(urlencode "http://blog.mro.name/foo")&title=Title&description=desc&source=curl"
url="${BASE_URL}?$params"

TOKEN=$(curl --dump-header head --cookie cook --cookie-jar cook --location --url "$url" 2>/dev/null | xsltproc --html response.xslt - 2>/dev/null | grep -F ' name="token" ' | cut -c 44-83)
# the precise length isn't important, it just has to be significantly larger than ''
token_length=$(printf "%s" $TOKEN | wc -c)
[ $token_length -eq 40 ] || { echo "expected TOKEN of 40 characters, but found $TOKEN of $token_length" && exit 1 ; }

# follow the redirect
echo "New URL: '$(grep -F "Location: " head | tail -n 1 | cut -c 10-)'"
url="${BASE_URL}?do=login&$params"
# curl --silent --cookie cook --cookie-jar cook --location --form "login=$USERNAME" --form "password=$PASSWORD" --form "token=$TOKEN" --url "$url" 2>/dev/null | xsltproc --html response.xslt - 2>/dev/null

# somehow travis+apache swallows the redirect from POST to GET:

echo == cook =======================================
cat cook
echo == head =======================================
cat head
echo ===============================================

curl --dump-header head --cookie cook --cookie-jar cook --location \
  --url "${BASE_URL}?do=login&post=http%3A%2F%2Fshaarli.review.mro.name%2F&title=Shaarli+-+sebsauvage.net+-+Review+Shaarli&source=curl" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "login=$USERNAME" \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "token=$TOKEN" \
  --data-urlencode "returnurl=http://heise.de" \
2>/dev/null \
| xsltproc --html response.xslt - 2>/dev/null

echo == cook =======================================
cat cook
echo == head =======================================
cat head
echo == data/log.txt ===============================
pwd
ls -l ../WebAppRoot/data/
cat ../WebAppRoot/data/log.txt
echo ===============================================

#   -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
#   -H 'Accept-Encoding: gzip, deflate' \
#   -H 'Accept-Language: de,en-US;q=0.7,en;q=0.3' \
#   -H 'Connection: keep-alive' \
#   -H 'Cookie: shaarli=821a57f40738b3ed34370ef0582a732d' \
#   -H 'Host: links.mro.name' \
#   -H 'Referer: http://links.mro.name/?do=login&post=http%3A%2F%2Fshaarli.review.mro.name%2F&title=Shaarli+-+sebsauvage.net+-+Review+Shaarli&source=bookmarklet' \
#   -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:40.0) Gecko/20100101 Firefox/40.0' \

# egrep -hoe "<input.*"

# echo ================

# TODO: watch out for error messages like e.g. ip bans or the like.

# check post-condition - there must be 2 entries now:
entries=-1
entries=$(curl --silent "$BASE_URL/?do=atom" | xmllint --encode utf8 --format - | grep --count "<entry>")
[ $entries -eq 2 ] || { echo "expected exactly two <entry>, found $entries" && exit 1 ; }
