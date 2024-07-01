#!/bin/sh

# Attempt to consumer the test data!
echo "\n\n##################################################"
echo "# Starting consumer-app"
echo "##################################################\n"
./gradlew consumer-app:run

# note: try modifying the consumer properties (consumer-app/consumer.properties) and rerunning