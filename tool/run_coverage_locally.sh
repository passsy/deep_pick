#!/bin/sh
set -e

(dart pub global list | grep coverage) || {
  # install coverage when not found
  dart pub global activate coverage
}
dart pub global run coverage:test_with_coverage
dart pub global run coverage:format_coverage \
    --packages=.dart_tool/package_config.json \
    --lcov \
    -i coverage/coverage.json \
    -o coverage/lcov.info

if type genhtml >/dev/null 2>&1; then
 genhtml -o coverage/html coverage/lcov.info
 echo "open coverage report $PWD/out/coverage/html/index.html"
else
 echo "genhtml not installed, can't generate html coverage output"
fi
