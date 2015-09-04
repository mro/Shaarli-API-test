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
url="${BASE_URL}?post=$(urlencode "http://blog.mro.name/foo")&title=$(urlencode "Title")&description=$(urlencode "desc")&source=$(urlencode "curl")"

TOKEN=$(curl --dump-header head --cookie cook --cookie-jar cook --location --url "$url" 2>/dev/null | xsltproc --html response.xslt - 2>/dev/null | grep -F ' name="token" ' | cut -c 44-83)
# the precise length doesn't matter, it just has to be significantly larger than ''
token_length=$(printf "%s" $TOKEN | wc -c)
[ $token_length -eq 40 ] || { echo "expected TOKEN of 40 characters, but found $TOKEN of $token_length" && exit 1 ; }

# follow the redirect
url1="${BASE_URL}$(grep -F 'Location: ' head | tr -d '\n' | head -c -1 | cut -c 11-)"
[ "$url1" != "" ] || { echo "Redirect URL unset." && exit 1 ; }
curl --silent --dump-header head --cookie cook --cookie-jar cook --location \
  --url "$url1" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "login=$USERNAME" \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "token=$TOKEN" \
  --data-urlencode "returnurl=$url" \
| xsltproc --html response.xslt - 2>/dev/null

# egrep -hoe "<input.*"

# echo ================

# TODO: watch out for error messages like e.g. ip bans or the like.

# check post-condition - there must be 2 entries now:
entries=-1
entries=$(curl --silent "$BASE_URL/?do=atom" | xmllint --encode utf8 --format - | grep --count "<entry>")
[ $entries -eq 2 ] || { echo "expected exactly two <entry>, found $entries" && exit 1 ; }
