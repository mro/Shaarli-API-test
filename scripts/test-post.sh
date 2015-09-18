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
. ./assert.sh

# Check preliminaries
curl --version >/dev/null       || assert_fail 101 "I need curl."
xmllint --version 2> /dev/null  || assert_fail 102 "I need xmllint (libxml2)."
ruby --version > /dev/null      || assert_fail 103 "I need ruby."
[ "$USERNAME" != "" ]           || assert_fail 1 "How strange, USERNAME is unset."
[ "$PASSWORD" != "" ]           || assert_fail 2 "How strange, PASSWORD is unset."
[ "$BASE_URL" != "" ]           || assert_fail 3 "How strange, BASE_URL is unset."

echo "###################################################"
echo "## Non-logged-in Atom feed before adding a link (should have only the initial public default entry):"
curl --silent --show-error --output curl.tmp.atom "$BASE_URL/?do=atom"
xmllint --encode utf8 --format curl.tmp.atom
entries=$(xmllint --xpath 'count(/*/*[local-name()="entry"])' curl.tmp.atom)
[ $entries -eq 1 ] || assert_fail 4 "Atom feed expected 1 = $entries"

echo "####################################################"
echo "## Step 1: fetch token to login and add a new link: "
echo "GET ${BASE_URL}?post=..."
rm curl.tmp.*
# http://unix.stackexchange.com/a/157219
LOCATION=$(curl --get --url "$BASE_URL" \
  --data-urlencode "post=https://github.com/sebsauvage/Shaarli/commit/450342737ced8ef2864b4f83a4107a7fafcc4add" \
  --data-urlencode "title=Initial Commit to Shaarli on Github." \
  --data-urlencode "source=Source Text" \
  --cookie curl.cook --cookie-jar curl.cook \
  --location --output curl.tmp.html \
  --trace-ascii curl.tmp.trace --dump-header curl.tmp.head \
  --write-out '%{url_effective}' 2>/dev/null)
# todo:
errmsg=$(xmllint --html --nowarning --xpath 'string(/html[1 = count(*)]/head[1 = count(*)]/script[starts-with(.,"alert(")])' curl.tmp.html)
[ "$errmsg" = "" ] || assert_fail 107 "error: '$errmsg'"
TOKEN=$(xmllint --html --nowarning --xpath 'string(/html/body//form[@name="loginform"]//input[@name="token"]/@value)' curl.tmp.html)
# string(..) http://stackoverflow.com/a/18390404

# the precise length doesn't matter, it just has to be significantly larger than ''
[ $(printf "%s" $TOKEN | wc -c) -eq 40 ] || assert_fail 6 "expected TOKEN of 40 characters, but found $TOKEN of $(printf "%s" $TOKEN | wc -c)"

echo "######################################################"
echo "## Step 2: follow the redirect, do the login and get the post form: "
echo "POST $LOCATION"
rm curl.tmp.*
LOCATION=$(curl --url "$LOCATION" \
  --data-urlencode "login=$USERNAME" \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "token=$TOKEN" \
  --cookie curl.cook --cookie-jar curl.cook \
  --location --output curl.tmp.html \
  --trace-ascii curl.tmp.trace --dump-header curl.tmp.head \
  --write-out '%{url_effective}' 2>/dev/null)
# todo:
errmsg=$(xmllint --html --nowarning --xpath 'string(/html[1 = count(*)]/head[1 = count(*)]/script[starts-with(.,"alert(")])' curl.tmp.html)
[ "$errmsg" = "" ] || assert_fail 108 "error: '$errmsg'"
# check presence of various mandatory form fields:
for field in lf_url lf_title lf_linkdate lf_tags token
do
  [ $(xmllint --html --nowarning --xpath "count(/html/body//form[@name = 'linkform']//input[@name='$field'])" curl.tmp.html) -eq 1 ] || assert_fail 8 "expected to have a '$field'"
done
for field in lf_description
do
  [ $(xmllint --html --nowarning --xpath "count(/html/body//form[@name = 'linkform']//textarea[@name='$field'])" curl.tmp.html) -eq 1 ] || assert_fail 8 "expected to have a '$field'"
done

# turn form field data into curl post data file
xmllint --html --nowarning --xmlout curl.tmp.html | xmllint --xpath '/html/body//form[@name="linkform"]' - | ruby form2post.rb > curl.post

echo "######################################################"
echo "## Step 3: finally post the link: "
echo "POST $LOCATION"
rm curl.tmp.*
LOCATION=$(curl --url "$LOCATION" \
  --data "@curl.post" \
  --data-urlencode "lf_linkdate=20130226_100941" \
  --data-urlencode "lf_source=$0" \
  --data-urlencode "lf_description=Must be older because http://sebsauvage.github.io/Shaarli/ mentions 'Copyright (c) 2011 Sébastien SAUVAGE (sebsauvage.net)'." \
  --data-urlencode "lf_tags=t1 t2" \
  --data-urlencode "returnurl=?foo" \
  --data-urlencode "save_edit=Save" \
  --cookie curl.cook --cookie-jar curl.cook \
  --location --output curl.tmp.html \
  --trace-ascii curl.tmp.trace --dump-header curl.tmp.head \
  --write-out '%{url_effective}' 2>/dev/null)
# sadly setting the returnurl doesn't make a difference
# todo:
errmsg=$(xmllint --html --nowarning --xpath 'string(/html[1 = count(*)]/head[1 = count(*)]/script[starts-with(.,"alert(")])' curl.tmp.html 2>/dev/null)
[ "$errmsg" = "" ] || assert_fail 107 "error: '$errmsg'"
# community shaarli doesn't redirect to the added url no more, so how can we detect success? https://github.com/shaarli/Shaarli/commit/35c2c4db5b5179e571023ab7fa7d3ecc03c85391
# echo "$LOCATION" | egrep -e "^${BASE_URL}/\?#[a-zA-Z0-9_-]{6}\$" || assert_fail 108 "expected link hash url, but got '$LOCATION'"
[ 1 -eq $(xmllint --html --nowarning --xpath "count(/html/body//a[@href = '?do=logout'])" curl.tmp.html 2>/dev/null) ] || assert_fail 13 "I expected a logout link."

#####################################################
# TODO: watch out for error messages like e.g. ip bans or the like.

# check post-condition - there must be more entries now:
echo "###################################################"
echo "## Non-logged-in Atom feed after adding a link (should have the added + the initial public default entry):"
curl --silent --show-error --output curl.tmp.atom "$BASE_URL/?do=atom"
xmllint --encode utf8 --format curl.tmp.atom
entries=$(xmllint --xpath 'count(/*/*[local-name()="entry"])' curl.tmp.atom)
[ $entries -eq 2 ] || assert_fail 10 "Atom feed expected 2 = $entries"
