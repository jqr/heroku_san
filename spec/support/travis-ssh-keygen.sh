#!/bin/sh

ssh-keygen -f ~/.ssh/id_rsa -C travis${TRAVIS_BUILD_ID}@example.com -N ''
