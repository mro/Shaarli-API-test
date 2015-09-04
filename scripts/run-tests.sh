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
cd "$(dirname "$0")/.."
CWD=$(pwd)

status_code=0
for tst in ./scripts/test*.sh
do
  printf "Running %s ... " "$(basename "$tst")"
  cd "$CWD"
  # prepare a clean test environment from scratch
  rm -rf WebAppRoot
  # ...and unpack into directory 'WebAppRoot'...
  tar -xzf source.tar.gz || { echo "ouch" && exit 1 ; }
  mv $GITHUB_SRC_SUBDIR WebAppRoot
  sudo service apache2 restart >/dev/null 2>&1

  ls -l "WebAppRoot/index.php" >/dev/null || { echo "ouch" && exit 2 ; }

  # curl "$BASE_URL" -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: de,en-US;q=0.7,en;q=0.3' -H 'Connection: keep-alive' -H 'Cookie: shaarli=a5929a34b29600fe02d657a976a22664' -H 'Host: shaarli.review.mro.name' -H 'Referer: http://shaarli.review.mro.name/' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:40.0) Gecko/20100101 Firefox/40.0' -H 'Content-Type: application/x-www-form-urlencoded' --data 'setlogin=tast&setpassword=tust&continent=Europe&city=Brussels&title=Review+Shaarli&Save=Save+config'
  curl --silent "$BASE_URL" -H 'Content-Type: application/x-www-form-urlencoded' --data "setlogin=$USERNAME&setpassword=$PASSWORD&continent=Europe&city=Brussels&title=Review+Shaarli&Save=Save+config" >/dev/null

  # execute each test
  sh "$tst"
  code=$?
  if [ $code -eq 0 ] ; then
    echo "successful"
  else
    echo "failed with code: $code"
    for f in scripts/curl.* WebAppRoot/data/log.txt ; do
      echo "== $f =============================="
      cat "$f"
    done
    status_code=1
  fi
done

exit $status_code
