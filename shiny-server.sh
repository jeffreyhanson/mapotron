#!/bin/sh
shiny-server > /var/log/shiny-server/shiny-server.log 2>&1
touch ~/test.txt
