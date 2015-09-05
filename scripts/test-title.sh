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

curl --url "$BASE_URL" \
  --cookie curl.cook --cookie-jar curl.cook \
  --location --output curl.html \
  --trace-ascii curl.trace --dump-header curl.head \
  2>/dev/null
xsltproc --html --output curl.xml response.xslt curl.html 2>/dev/null

[ "Review Shaarli" = "$(xmllint --xpath 'string(/shaarli/@title)' curl.xml)" ] || { echo "title not found" && exit 1 ; }
