#!/bin/bash
HOSTS="
localhost
"
for H in $HOSTS
do
echo START SCRIPT:
date +%x-%R
(
sleep 1;
echo -en "EHLO debug\r\n";
sleep 1;
) | telnet $H 25
echo ===================================
done