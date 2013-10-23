#!/bin/sh

heroku keys:remove travis${TRAVIS_BUILD_ID}@example.com
