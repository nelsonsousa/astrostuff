#!/bin/bash

LOGPATH=${HOME}/Logs/indigo
LOGFILE=indigo.log

cd $LOGPATH

if [ -f "$LOGFILE" ]; then
  ts="$(date -r "$LOGFILE" +%Y-%m-%d_%H:%M:%S)"
  mv  $LOGFILE indigo_$ts.log
  gzip indigo_$ts.log
  touch indigo.log
fi


if [ $# -eq 0 ]
  then
    ARGS="-v"
  else
    ARGS=$@
fi

/usr/bin/indigo_server $ARGS --enable-rpi-management > $LOGFILE 2>&1
