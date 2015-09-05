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

# Check preliminaries
curl --version >/dev/null || { echo "I need curl." && exit 101 ; }
xmllint --version 2> /dev/null || { echo "I need xmllint." && exit 102 ; }
ruby --version > /dev/null || { echo "I need xmllint." && exit 103 ; }

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

  curl --silent --show-error \
    --url "$BASE_URL" \
    --data-urlencode "setlogin=$USERNAME" \
    --data-urlencode "setpassword=$PASSWORD" \
    --data-urlencode "continent=Europe" \
    --data-urlencode "city=Brussels" \
    --data-urlencode "title=Review Shaarli" \
    --data-urlencode "Save=Save config" \
    --output /dev/null

  # execute each test
  sh "$tst"
  code=$?
  if [ $code -eq 0 ] ; then
    echo "success"
  else
    echo "failed with code: $code"
    echo -n 'travis_fold:start:#{$tst}\r'
    printf " %-60s \n" "_BEGIN_$tst_debug_output_" | tr ' _' '> '
    for f in scripts/curl.* WebAppRoot/data/log.txt ; do
    	printf " %-60s \n" "_$f_" | tr ' _' '# '
      cat "$f"
    done
    printf " %-60s \n" "_END_$tst_debug_output_" | tr ' _' '< '
    echo ". "
    echo -n 'travis_fold:end:#{$tst}\r'
    status_code=1
  fi
done

exit $status_code
