#!/bin/bash

trap "echo 'Received SIGINT'; exit" INT
trap "echo 'Received SIGTERM'; exit" TERM

echo "I am sleeping and waiting for a signal..."
while true; do
  sleep infinity &
  wait $!
done
