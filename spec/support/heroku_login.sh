#!/bin/sh

heroku login <<EOT
heroku_san
$HEROKU_SAN_API_KEY
EOT
heroku auth:whoami