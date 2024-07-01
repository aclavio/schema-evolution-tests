#!/bin/sh

# Register the schemas
echo "\n\n##################################################"
echo "# Registering updated schemas"
echo "##################################################\n"
## AccountCreated v2
curl -s -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema":"{\"namespace\":\"stream.processing.demo\",\"type\":\"record\",\"name\":\"AccountCreated\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"owner\",\"type\":\"string\"},{\"name\":\"comment\",\"type\":\"string\",\"default\":\"N/A\"}]}"}' \
  http://localhost:8081/subjects/stream.processing.demo.AccountCreated/versions
## Register an updated union.test.avro-value schema - incrementing the reference to the AccountCreated schema v2
curl -s -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"references": [{"name": "stream.processing.demo.AccountCreated","subject": "stream.processing.demo.AccountCreated","version": 2},{"name": "stream.processing.demo.AccountUpdated","subject": "stream.processing.demo.AccountUpdated","version": 1},{"name": "stream.processing.demo.AccountDeleted","subject": "stream.processing.demo.AccountDeleted","version": 1}],"schema": "[ \"stream.processing.demo.AccountCreated\", \"stream.processing.demo.AccountUpdated\", \"stream.processing.demo.AccountDeleted\"]"}' \
  http://localhost:8081/subjects/union.test.avro-value/versions
## NOTE - keeping a reference to the old schema works as expected
#curl -s -X POST \
#  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
#  --data '{"references": [{"name": "stream.processing.demo.AccountCreated","subject": "stream.processing.demo.AccountCreated","version": 1},{"name": "stream.processing.demo.AccountCreated","subject": "stream.processing.demo.AccountCreated","version": 2},{"name": "stream.processing.demo.AccountUpdated","subject": "stream.processing.demo.AccountUpdated","version": 1},{"name": "stream.processing.demo.AccountDeleted","subject": "stream.processing.demo.AccountDeleted","version": 1}],"schema": "[ \"stream.processing.demo.AccountCreated\", \"stream.processing.demo.AccountUpdated\", \"stream.processing.demo.AccountDeleted\"]"}' \
#  http://localhost:8081/subjects/union.test.avro-value/versions

# create v1 test data
echo "\n\n##################################################"
echo "# Starting producer-app-v2"
echo "##################################################\n"
./gradlew producer-app-v2:run