#!/bin/sh
cd "$(dirname "$0")/.."
CWD=$(pwd)

status_code=0
for tst in ./scripts/test*.sh
do
  echo "Running $(basename "$tst")..."
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

  # execute all tests
  if [ sh "$tst" ] ; then
    echo " successful"
  else
    echo " failed"
    status_code=1
  fi
done

exit $status_code
