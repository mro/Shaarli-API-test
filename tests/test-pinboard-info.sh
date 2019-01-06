#!/bin/sh
#
#  Copyright (c) 2019-2019 Marcus Rohrmoser https://code.mro.name/mro/Shaarli-API-test. All rights reserved.
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
cd "$(dirname "$0")/../tmp"
. ../scripts/assert.sh

# Check preliminaries
curl --version >/dev/null       || assert_fail 101 "I need curl."
xmllint --version 2> /dev/null  || assert_fail 102 "I need xmllint (libxml2)."
[ "${BASE_URL}" != "" ]         || assert_fail 1 "How strange, BASE_URL is unset."

curl --url "${BASE_URL}/pinboard.cgi/v1/info" 2>/dev/null | file -
