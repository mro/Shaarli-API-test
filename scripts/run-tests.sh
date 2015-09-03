#!/bin/sh
cd "$(dirname "$0")"

status_code=0
for tst in ./scripts/test*.sh
do
  # prepare a clean test environment from scratch
  rm -rf WebAppRoot
  # ...and unpack into directory 'WebAppRoot'...
  tar -xzf source.tar.gz || { echo "ouch" && exit 1 ; }
  mv $GITHUB_SRC_SUBDIR WebAppRoot
  ls -l "WebAppRoot/index.php" >/dev/null || { echo "ouch" && exit 2 ; }

  echo "TODO: set up the shaarli instance."
  echo "TODO: register a user."

  # execute all tests
  sh "$tst" || { status_code=1 ; }
done

exit $status_code
