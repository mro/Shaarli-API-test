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

# terminal colors (require bash)
# http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html
# http://wiki.bash-hackers.org/scripting/terminalcodes
FGC_NONE="\033[0m"
FGC_GRAY="\033[1;30m"
FGC_RED="\033[1;31m"
FGC_GREEN="\033[1;32m"
FGC_YELLOW="\033[1;33m"
FGC_BLUE="\033[1;34m"
FGC_PURPLE="\033[1;35m"
FGC_CYAN="\033[1;36m"
FGC_WHITE="\033[1;37m"
BGC_GRAY="\033[7;30m"
BGC_RED="\033[7;31m"
BGC_GREEN="\033[7;32m"
BGC_YELLOW="\033[7;33m"
BGC_BLUE="\033[7;34m"
BGC_PURPLE="\033[7;35m"
BGC_CYAN="\033[7;36m"
BGC_WHITE="\033[7;37m"

echo "\$ curl --version" ; curl --version

status_code=0
for tst in ./scripts/test*.sh
do
  test_name="$(basename "$tst")"
  echo -n "travis_fold:start:${test_name}\r"
  echo -n "Running $test_name "

  cd "$CWD"
  # prepare a clean test environment from scratch
  rm scripts/curl.* 1>/dev/null 2>&1
  rm -rf WebAppRoot
  # ...and unpack into directory 'WebAppRoot'...
  tar -xzf source.tar.gz || { echo "ouch" && exit 1 ; }
  mv $GITHUB_SRC_SUBDIR WebAppRoot

  # http://robbiemackay.com/2013/05/03/automating-behat-and-mink-tests-with-travis-ci/
  # webserver setup
  php -S 127.0.0.1:8000 -t WebAppRoot 1> php.stdout 2> php.stderr &
  # sleep 1 # how could we get rid of this stupid sleep?

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

  killall php 1>/dev/null 2>&1
  if [ $code -ne 0 ] ; then
    for f in scripts/curl.* WebAppRoot/data/log.txt ; do
      printf " %-60s \n" "_${f}_" | tr ' _' '# '
      cat "$f"
    done
    echo ". "
  fi
  echo -n "travis_fold:end:${test_name}\r"

  if [ $code -eq 0 ] ; then
    echo "${FGC_GREEN}✓${FGC_NONE} ${test_name}"
  else
    echo "${FGC_RED}✗${FGC_NONE} ${test_name} (code: $code)"
    status_code=1
  fi
  wait
done

exit $status_code
