#!/bin/bash
# LOGDIR which value is the nginx logs directory
LOGDIR="/usr/local/nginx/logs"
# ACLOG and ERLOG is the basic name of nginx logs file name
ACLOG="access.log"
ERLOG="error.log"
# Just keep old logs file in 15 days.
ROTATE=15
# The file suffix which is add after the logs file name. Using date.
DATEEXT="-$(date -d "1days ago" +"%y%m%d")"
RMEXT="-$(date -d "${ROTATE}days ago" +"%y%m%d")"
# The NGINX daemon script
NGINX_SCRIPT="/usr/local/nginx/nginx"

if [ ! -e $NGINX_SCRIPT ]
then
    echo "The nginx daemon script is not existing."
    exit 1
fi
if [ -d "$LOGDIR" ]
then 
    cd $LOGDIR
    pwd
    if [ -e $ACLOG -a -e $ERLOG ]
    then
        if [ -e "$ACLOG$RMEXT" ] 
        then
            rm -f $ACLOG$RMEXT
        fi
        if [ -e "$ERLOG$RMEXT" ]
        then
	    rm -f $ERLOG$RMEXT
        fi
    else
        echo "Nginx logs is not in $LOGDIR"
        exit 3
    fi
    
else
    echo "$LOGDIR isn't exist"
    exit 2
fi
if [ -e "$ACLOG" ]
then
    mv $ACLOG $ACLOG$DATEEXT
    ACSU=$?
fi

if [ -e "$ERLOG" ]
then
    mv $ERLOG $ERLOG$DATEEXT
    ERSU=$?
fi
COUNT=0
while [ ! -e $ACLOG -a ! -e $ERLOG -a $COUNT -lt 10 ]
do
    if [ "$ACSU" -eq 0 -a "$ERSU" -eq 0 ]
    then
        $NGINX_SCRIPT -s reopen
    fi
    COUNT=$(( COUNT + 1))
done

