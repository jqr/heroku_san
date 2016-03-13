#!/bin/sh -x

heroku login <<EOT
apikey
$HEROKU_SAN_API_KEY
EOT
