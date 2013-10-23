#!/bin/sh

heroku keys:remove travis-${TRAVIS_JOB_NUMBER}@example.com
