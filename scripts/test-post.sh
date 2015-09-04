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

[ "$USERNAME" != "" ] || { echo "How strange, USERNAME is unset." && exit 1 ; }
[ "$PASSWORD" != "" ] || { echo "How strange, PASSWORD is unset." && exit 2 ; }
[ "$BASE_URL" != "" ] || { echo "How strange, BASE_URL is unset." && exit 3 ; }

# check pre-condition - there's already 1 public entry in the ATOM feed:
entries=-1
entries=$(curl --silent "$BASE_URL/?do=atom" | xmllint --encode utf8 --format - | grep --count "<entry>")
[ $entries -eq 1 ] || { echo "expected exactly one <entry>, found $entries" && exit 4 ; }

#####################################################
# Step 1: fetch token to login and add a new link:
TOKEN=$(curl --get --url "$BASE_URL" \
  --data-urlencode "post=http://blog.mro.name/foo" \
  --data-urlencode "title=Title Text" \
  --data-urlencode "description=Desc Text" \
  --data-urlencode "source=Source Text" \
  --dump-header curl.head --cookie curl.cook --cookie-jar curl.cook --location --silent \
| xsltproc --html response.xslt - 2>/dev/null \
| xmllint --xpath 'string(/shaarli/input[@name="token"]/@value)' -)
# string(..) http://stackoverflow.com/a/18390404

# the precise length doesn't matter, it just has to be significantly larger than ''
[ $(printf "%s" $TOKEN | wc -c) -eq 40 ] || { echo "expected TOKEN of 40 characters, but found $TOKEN of $(printf "%s" $TOKEN | wc -c)" && exit 5 ; }

#####################################################
# Step 2: follow the redirect and get the post form:
echo "URL: '${BASE_URL}$(grep -F 'Location: ' curl.head | tr -d '\n' | cut -c 11-)'"

curl --url "${BASE_URL}$(grep -F 'Location: ' curl.head | tr -d '\n' | cut -c 11-)" \
  --data-urlencode "login=$USERNAME" \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "token=$TOKEN" \
  --dump-header curl.head --cookie curl.cook --cookie-jar curl.cook --location --trace-ascii curl.trace 2>/dev/null \
| xsltproc --html --output curl.xml response.xslt - 2>/dev/null

[ $(xmllint --xpath 'count(/shaarli/is_logged_in[@value="true"])' curl.xml) -eq 1 ] || { echo "expected to be logged in now" && exit 6 ; }

# turn response.xml form input field data into curl commandline parameters or post file
ruby response2post.rb < curl.xml > curl.post

#####################################################
# Step 3: finally post the link:
curl --url "${BASE_URL}$(grep -F 'Location: ' curl.head | tr -d '\n' | cut -c 11-)" \
  --data "@${tmp}.post" \
  --data-urlencode "lf_source=$0" \
  --data-urlencode "lf_tags=t1 t2" \
  --data-urlencode "save_edit=Save" \
  --dump-header curl.head --cookie curl.cook --cookie-jar curl.cook --location --trace-ascii curl.trace 2>/dev/null \
| xsltproc --html --output curl.xml response.xslt - 2>/dev/null

#####################################################
[ $(xmllint --xpath 'count(/shaarli/is_logged_in[@value="true"])' curl.xml) -eq 1 ] || { echo "expected to be still logged in" && exit 7 ; }
# TODO: watch out for error messages like e.g. ip bans or the like.
# check post-condition - there must be 2 entries now:
[ $(curl --silent "$BASE_URL/?do=atom" | xmllint --xpath 'count(/*/*[local-name()="entry"])' -) -eq 2 ] || { echo "expected exactly two <entry>, found $entries" && exit 18 ; }
