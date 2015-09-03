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

url="${BASE_URL}"
curl --silent --location --url "$url" 2>/dev/null | xsltproc --html response.xslt -

count=0
count=$(curl --silent --location --url "$url" 2>/dev/null | xsltproc --html response.xslt - | grep --fixed-strings '<shaarli title="Review Shaarli">')
[ $count -eq 1 ] || { echo "title not found" && exit 1 ; }
