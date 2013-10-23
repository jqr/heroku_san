#!/bin/sh

ssh-keygen -f ~/.ssh/id_rsa -C travis-${TRAVIS_JOB_ID}@example.com -N ''
