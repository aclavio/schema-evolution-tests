#!/bin/sh

GROUP_ID=test-consumer

echo "Resetting offsets for $GROUP_ID"

kafka-consumer-groups \
  --bootstrap-server localhost:29092 \
  --group $GROUP_ID \
  --reset-offsets \
  --all-topics \
  --to-earliest \
  --execute