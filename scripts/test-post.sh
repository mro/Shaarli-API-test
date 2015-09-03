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

entries=-1
entries=$(curl --silent "$BASE_URL/?do=atom" | xmllint --encode utf8 --format - | grep --count "<entry>")
[ $entries -eq 1 ] || { echo "expected exactly one <entry>, found $entries" && exit 1 ; }

url="${BASE_URL}?post=http://blog.mro.name/foo&title=Title&description=desc&source=curl"
TOKEN=$(curl --cookie-jar cook --location --url "$url" 2>/dev/null | grep token | cut -c 46-85)
# echo ================

url="${BASE_URL}?do=login&post=http://blog.mro.name/foo&title=Title&description=desc&source=curl"
curl --silent --cookie cook --cookie-jar cook --location --form "login=$USERNAME" --form "password=$PASSWORD" --form "token=$TOKEN" --url "$url" 2>/dev/null | xsltproc response.xslt -
# egrep -hoe "<input.*"

# echo ================

# TODO: watch out for error messages like e.g. ip bans or the like.

# Test success:
entries=-1
entries=$(curl --silent "$BASE_URL/?do=atom" | xmllint --encode utf8 --format - | grep --count "<entry>")
[ $entries -eq 2 ] || { echo "expected exactly two <entry>, found $entries" && exit 1 ; }
