#!/bin/sh

echo $(phpenv)


curl --location --head http://localhost/index.php
exit $?

echo "No tests implemented so far."

exit 1
