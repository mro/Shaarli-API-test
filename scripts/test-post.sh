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
xsltproc --version > /dev/null  || assert_fail 102 "I need xsltproc."
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
xsltproc --html --output curl.tmp.xml response.xslt curl.tmp.html 2>/dev/null || assert_fail 5 "Failed to fetch TOKEN"
xmllint --relaxng response.rng curl.tmp.xml || assert_fail 5 "Response invalid."

errmsg=$(xmllint --xpath 'string(/shaarli/error/@message)' curl.tmp.xml)
[ "$errmsg" = "" ] || assert_fail 107 "error: '$errmsg'"
TOKEN=$(xmllint --xpath 'string(/shaarli/form[@name="loginform"]/input[@name="token"]/@value)' curl.tmp.xml)
# string(..) http://stackoverflow.com/a/18390404

# the precise length doesn't matter, it just has to be significantly larger than ''
[ $(printf "%s" $TOKEN | wc -c) -eq 40 ] || assert_fail 6 "expected TOKEN of 40 characters, but found $TOKEN of $(printf "%s" $TOKEN | wc -c)"

echo "######################################################"
echo "## Step 2: follow the redirect, do the login and get the post form: "
rm curl.tmp.*
LOCATION=$(curl --url "$LOCATION" \
  --data-urlencode "login=$USERNAME" \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "token=$TOKEN" \
  --cookie curl.cook --cookie-jar curl.cook \
  --location --output curl.tmp.html \
  --trace-ascii curl.tmp.trace --dump-header curl.tmp.head \
  --write-out '%{url_effective}' 2>/dev/null)
xsltproc --html --output curl.tmp.xml response.xslt curl.tmp.html 2>/dev/null || assert_fail 7 "Failure"
xmllint --relaxng response.rng curl.tmp.xml || assert_fail 5 "Response invalid."
errmsg=$(xmllint --xpath 'string(/shaarli/error/@message)' curl.tmp.xml)
[ "$errmsg" = "" ] || assert_fail 108 "error: '$errmsg'"
[ $(xmllint --xpath 'count(/shaarli/is_logged_in[@value="true"])' curl.tmp.xml) -eq 1 ] || assert_fail 8 "expected to be logged in now"

# turn response.xml form input field data into curl commandline parameters or post file
ruby response2post.rb < curl.tmp.xml > curl.post

echo "######################################################"
echo "## Step 3: finally post the link: "
rm curl.tmp.*
curl --url "$LOCATION" \
  --data "@curl.post" \
  --data-urlencode "lf_linkdate=20130226_100941" \
  --data-urlencode "lf_source=$0" \
  --data-urlencode "lf_description=Must be older because http://sebsauvage.github.io/Shaarli/ mentions 'Copyright (c) 2011 Sébastien SAUVAGE (sebsauvage.net)'." \
  --data-urlencode "lf_tags=t1 t2" \
  --data-urlencode "save_edit=Save" \
  --cookie curl.cook --cookie-jar curl.cook \
  --location --output curl.tmp.html \
  --trace-ascii curl.tmp.trace --dump-header curl.tmp.head \
  2>/dev/null
xsltproc --html --output curl.tmp.xml response.xslt curl.tmp.html 2>/dev/null
xmllint --relaxng response.rng curl.tmp.xml || assert_fail 5 "Response invalid."

#####################################################
[ $(xmllint --xpath 'count(/shaarli/is_logged_in[@value="true"])' curl.tmp.xml) -eq 1 ] || assert_fail 9 "expected to be still logged in"
# TODO: watch out for error messages like e.g. ip bans or the like.

# check post-condition - there must be more entries now:
echo "###################################################"
echo "## Non-logged-in Atom feed after adding a link (should have the added + the initial public default entry):"
curl --silent --show-error --output curl.tmp.atom "$BASE_URL/?do=atom"
xmllint --encode utf8 --format curl.tmp.atom
entries=$(xmllint --xpath 'count(/*/*[local-name()="entry"])' curl.tmp.atom)
[ $entries -eq 2 ] || assert_fail 10 "Atom feed expected 2 = $entries"
