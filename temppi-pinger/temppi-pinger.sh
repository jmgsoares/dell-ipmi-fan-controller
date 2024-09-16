#!/bin/bash

#IPMI access data
IPMIHOST=192.168.1.1
IPMIUSER=root
IPMIPW=calvin
IPMIEK=0000000000000000000000000000000000000000

# IP address or hostname of the device to ping
HOST="192.168.1.1"
# Number of consecutive failed pings before taking action
MAX_FAILURES=3
# The command to execute when the device does not respond
COMMAND_TO_EXECUTE="ipmitool -I lanplus -H "$IPMIHOST" -U "$IPMIUSER" -P "$IPMIPW" -y "$IPMIEK" raw 0x30 0x30 0x01 0x01"

# Counter for consecutive ping failures
failure_count=0

while true; do
  # Ping the host once
  if ping -c 1 "$HOST" > /dev/null 2>&1; then
    # If ping is successful, reset the failure counter
    failure_count=0
    echo "Ping OK"
  else
    # Increment the failure counter on failed ping
    ((failure_count++))
    echo "Ping NOK ($failure_count/$MAX_FAILURES)"
  fi

  # If the failure count reaches MAX_FAILURES, execute the command
  if [ "$failure_count" -ge "$MAX_FAILURES" ]; then
    echo "Max failures reached, setting fans to auto..."
    eval "$COMMAND_TO_EXECUTE"
    # Reset failure counter
    failure_count=0
  fi

  # Wait for 2 seconds
  sleep 2
done
