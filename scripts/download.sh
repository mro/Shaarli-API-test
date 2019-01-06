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
cd "$(dirname "$0")/.." || exit 1

[ "${GITHUB}" != "" ] || { echo 'I need ${GITHUB}, e.g. shaarli/Shaarli/archive/v0.0.40beta' && exit 2; }

# Download the tarball...
GITHUB_SRC_URL="https://github.com/${GITHUB}.tar.gz"
curl --location --output source.tar.gz --url "${GITHUB_SRC_URL}" || { echo "ouch" && exit 3; }
