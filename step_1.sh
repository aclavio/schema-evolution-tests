#!/bin/sh

# Set Schema Compatibility to Forward/Full Compatible
echo "\n\n##################################################"
echo "# Setting schema compatibility mode to FULL"
echo "##################################################\n"
curl -s -X PUT \
  --data '{"compatibility": "FULL"}' -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  http://localhost:8081/config

# Create the test topic
echo "\n\n##################################################"
echo "# Creating the test topic \"union.test.avro\""
echo "##################################################\n"
kafka-topics \
  --bootstrap-server localhost:29092 \
  --create \
  --partitions 1 \
  --replication-factor 1 \
  --topic union.test.avro

# Register the schemas
echo "\n\n##################################################"
echo "# Registering schemas"
echo "##################################################\n"
## AccountCreated v1
curl -s -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema":"{\"namespace\":\"stream.processing.demo\",\"type\":\"record\",\"name\":\"AccountCreated\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"owner\",\"type\":\"string\"}]}"}' \
  http://localhost:8081/subjects/stream.processing.demo.AccountCreated/versions
## AccountUpdated
curl -s -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema":"{\"namespace\":\"stream.processing.demo\",\"type\":\"record\",\"name\":\"AccountUpdated\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"int\"}]}"}' \
  http://localhost:8081/subjects/stream.processing.demo.AccountUpdated/versions
## AccountDeleted
curl -s -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema":"{\"namespace\":\"stream.processing.demo\",\"type\":\"record\",\"name\":\"AccountDeleted\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"}]}"}' \
  http://localhost:8081/subjects/stream.processing.demo.AccountDeleted/versions
## union.test.avro-value v1
curl -s -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"references": [{"name": "stream.processing.demo.AccountCreated","subject": "stream.processing.demo.AccountCreated","version": 1},{"name": "stream.processing.demo.AccountUpdated","subject": "stream.processing.demo.AccountUpdated","version": 1},{"name": "stream.processing.demo.AccountDeleted","subject": "stream.processing.demo.AccountDeleted","version": 1}],"schema": "[ \"stream.processing.demo.AccountCreated\", \"stream.processing.demo.AccountUpdated\", \"stream.processing.demo.AccountDeleted\"]"}' \
  http://localhost:8081/subjects/union.test.avro-value/versions

# create v1 test data
echo "\n\n##################################################"
echo "# Starting producer-app-v1"
echo "##################################################\n"
./gradlew producer-app-v1:run