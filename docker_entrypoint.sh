#!/usr/bin/dumb-init /bin/bash
USER_ID=${DATA_USER_ID:-1000}
GROUP_ID=${DATA_GROUP_ID:-1000}
CONFIG=${CONFIG_FILE:-"./haproxy.cfg"}
WATCH_FILES="$CONFIG $EXTRA_WATCH_FILES"

function log() { echo "`date +'%Y/%m/%d %T'` <container> $@"; }

#Update unprivileged user
groupmod -g ${GROUP_ID} haproxy
usermod -u ${USER_ID} -g haproxy -G www-data haproxy
chown haproxy:haproxy /haproxy-data

cd /haproxy-data

../haproxy -vv
PID_FILE="/tmp/haproxy.pid"
CHECK_CONFIG_CMD="../haproxy -c -f $CONFIG"
STORE_OLD_CFG="cp $CONFIG /tmp/old_haproxy.cfg"
RUN_HAPROXY_CMD="../haproxy -f $CONFIG -W -p $PID_FILE"

$STORE_OLD_CFG
$CHECK_CONFIG_CMD || exit $?

export PARENT=$$
( $RUN_HAPROXY_CMD || ( echo 'exit code:' $? && kill -15 -$PARENT ) ) &

sleep 2

log "Started haproxy"
log "Listening for $WATCH_FILES changes."

while inotifywait -q -r -e modify,attrib,create,delete $WATCH_FILES; do
  if [ -f $PID_FILE ] ; then
    sleep 5 #graceful period for mutiple files update
    log "Config $CONFIG update event received, diff: "
    diff /tmp/old_haproxy.cfg $CONFIG
    log "Checking updated config"
    if $CHECK_CONFIG_CMD ; then
      log "Check OK, reloaded haproxy"
      $STORE_OLD_CFG
      kill -SIGUSR2 `cat $PID_FILE`
      log "Successfuly reloaded haproxy"
    else
      log "Check failed, no restart performed, haproxy will continue to use the old working config. Please fix the new config file."
    fi
  else
    log "Fatal, no PID file"
    exit 999
  fi
done

