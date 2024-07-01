# Schema Evolution Testing

This project demonstrates an issue with schema evolution and AVRO union types.

**Description of issue:**  When evolving avro schemas (in "forward" or "full" compatibility mode) which belong to a top-level union, a client will fail to deserialize a record using concrete classes generated from an older version of the schema; violating the promise of "forward" and "full" compatibility.     

This project sets up a self-contained environment for the testing of this issue.  

## Setup
Start the dockerized test environment

    docker compose up -d

## Execute Tests
**Step 1:**
- Sets the Schema Registry Compatibility mode
- Registers the initial schemas
- Publishes a set of test records


    ./step_1.sh

**Step 2:**
- Registers the evolved schemas
- Publishes a new set of test records


    ./step_2.sh

**Step 3:**
- Starts the consumer 
  - expected to fail when evolved schemas are encountered!


    ./step_3.sh

### Workarounds

Setting `specific.avro.reader=false` in the `consumer.properties` file prevents this issue.  Disabling this setting seems to stop the GenericRecord deserializer from using the incompatible newer schema from the registry with the older concrete SpecificRecord classes in the consumer application.


Registering the updated union schema with references to both the old, and new versions of the sub-schema prevents this issue.  Retaining a reference to the old schema seems to allow the GenericRecord deserializer to utilize the SpecificRecord deserializers with the older schema version.  eg:

```json
{
  "references": [
    {"name": "stream.processing.demo.AccountCreated","subject": "stream.processing.demo.AccountCreated","version": 1},
    {"name": "stream.processing.demo.AccountCreated","subject": "stream.processing.demo.AccountCreated","version": 2},
    {"name": "stream.processing.demo.AccountUpdated","subject": "stream.processing.demo.AccountUpdated","version": 1},
    {"name": "stream.processing.demo.AccountDeleted","subject": "stream.processing.demo.AccountDeleted","version": 1}
  ],
  "schema": "[ \"stream.processing.demo.AccountCreated\", \"stream.processing.demo.AccountUpdated\", \"stream.processing.demo.AccountDeleted\"]"
}
```

## Teardown
Stop the test environment

    docker compose down