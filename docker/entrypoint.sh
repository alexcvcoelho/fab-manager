#!/bin/sh
set -e
service ssh start
/usr/bin/supervisord -c /etc/supervisor/conf.d/fabmanager.conf