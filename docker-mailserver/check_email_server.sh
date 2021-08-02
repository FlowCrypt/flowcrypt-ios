#!/bin/bash

set -uxo pipefail

# this script tests the mailserver, make sure it accepts connections
# make sure that your /etc/hosts includes line "217.163.30.119 mail"

EMAILPORT=10025
EMAILHOST=mail
TMPFILE=/tmp/telnet-output.log

( sleep 1; echo -en "EHLO debug\r\n"; sleep 1; ) | telnet $EMAILHOST $EMAILPORT > $TMPFILE

set +x

if grep -Fxq "mail.flowcrypt.test" $TMPFILE
then
    echo "success - SMTP server at '$EMAILHOST' port '$EMAILPORT' is running"
else
    echo "failed to confirm that SMTP server is running at '$EMAILHOST' port '$EMAILPORT':"
    cat $TMPFILE
    exit 1
fi
