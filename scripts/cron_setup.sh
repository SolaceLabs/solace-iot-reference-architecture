#!/bin/bash

(crontab -l 2>/dev/null; echo "* * * * * /tmp/connection_count.sh") | crontab -
crontab -l
