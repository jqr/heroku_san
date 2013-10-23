#!/bin/sh

heroku keys:remove travis-${TRAVIS_JOB_ID}@example.com
