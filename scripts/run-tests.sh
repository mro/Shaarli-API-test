#!/bin/sh

echo $(phpenv)


curl --head http://localhost/index.php
exit $?

echo "No tests implemented so far."

exit 1
