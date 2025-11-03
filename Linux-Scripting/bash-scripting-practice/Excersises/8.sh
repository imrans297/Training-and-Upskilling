#!/bin/bash

PIDFILE="/tmp/sleep-walking-server.pid"

usage() {
  echo "Usage: sleep-walking start|stop"
  exit 1
}

start() {
  /tmp/sleep-walking-server &
  echo $! > "$PIDFILE"
  echo "sleep-walking server started."
}

stop() {
  if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" && rm -f "$PIDFILE"
    echo "sleep-walking server stopped."
  else
    echo "sleep-walking server is not running."
  fi
}

case "$1" in
  start) start ;;
  stop) stop ;;
  *) usage ;;
esac

#Create a startup script for an application called sleep­walking­server, which is provided below. The script should be named sleep­walking and accept "start" and "stop" as arguments. If anything other than "start" or "stop" is provided as an argument, display a usage statement: "Usage sleep­walking start|stop" and terminate the script with an exit status of 1.

#To start sleep­walking­server, use this command: "/tmp/sleep­walking­server &" To stop sleep­walking­server, use this command: "kill $(cat /tmp/sleep­walking­server.pid)"

#Here is the contents of "sleep­walking­server". Be sure to put this file in /tmp and run chmod 755 /tmp/sleep­walking­server

# #!/bin/bash
# PID_FILE="/tmp/sleep­walking­server.pid"
# trap "rm $PID_FILE; exit" SIGHUP SIGINT SIGTERM
# echo "$$" > $PID_FILE
# while true
# do    
#   :
# done