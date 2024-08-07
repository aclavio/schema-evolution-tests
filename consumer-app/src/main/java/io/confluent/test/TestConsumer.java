/*
 * This source file was generated by the Gradle 'init' task
 */
package io.confluent.test;

import org.apache.avro.Schema;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.specific.SpecificData;
import org.apache.avro.specific.SpecificRecordBase;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.errors.WakeupException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import stream.processing.demo.AccountCreated;
import stream.processing.demo.AccountDeleted;
import stream.processing.demo.AccountUpdated;

import java.io.FileInputStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.time.Duration;
import java.util.Arrays;
import java.util.List;
import java.util.Properties;
import java.util.concurrent.CountDownLatch;

public class TestConsumer implements Runnable {
    private static final Logger logger = LoggerFactory.getLogger(TestConsumer.class);

    private static final String DEFAULT_CONFIG_FILE = "consumer.properties";
    private static final String DEFAULT_TOPIC = "union.test.avro";

    private final KafkaConsumer<String, GenericRecord> consumer;
    //private final KafkaConsumer<String, SpecificRecordBase> consumer;

    private final List<String> topics;
    private final CountDownLatch shutdownLatch;

    public TestConsumer(Properties config, List<String> topics) {
        // initialize the Kafka Consumer using the properties file
        this.consumer = new KafkaConsumer<>(config);
        this.topics = topics;
        this.shutdownLatch = new CountDownLatch(1);
    }

    @Override
    public void run() {
        try {
            // subscribe to the Kafka topics
            consumer.subscribe(topics);

            logger.info("Waiting for events...");

            // basic Kafka consumer "poll loop"
            while (true) {
                // poll for new kafka events
                //ConsumerRecords<String, SpecificRecordBase> records = consumer.poll(Duration.ofMillis(1000));
                ConsumerRecords<String, GenericRecord> records = consumer.poll(Duration.ofMillis(1000));

                // application specific processing...
                records.forEach(record -> {
                    // for demo purposes, just emit a log statement
                    logger.info("[{} @{}] got record: [{}] {}",
                            record.topic(),
                            record.offset(),
                            record.key(),
                            record.value().toString());
                    logger.debug("value class: {}", record.value().getClass().getName());

                    // Attempt to convert the GenericRecord type from the union to the SpecificRecord type
                    // extracts the schema name from the GenericRecord, and finds the local generated version of that schema
                    // this works-around the evolution issue in conjunction with "specific.avro.reader=false"
                    GenericRecord genericRecord = record.value();
                    String className = genericRecord.getSchema().getFullName();
                    logger.debug("record uses schema: {}", className);
                    try {
                        Class<?> clazz = Class.forName(className);
                        Method getClassSchemaMethod = clazz.getDeclaredMethod("getClassSchema");
                        Schema schema = (Schema) getClassSchemaMethod.invoke(null);
                        Object specificData = SpecificData.get().deepCopy(schema, record.value());
                        logger.info("TEST converted to specific record type [{}]: {}", specificData.getClass().getName(), specificData);
                    } catch (ClassNotFoundException ex) {
                        logger.error("SpecificRecord class \"{}\" not found!", className);
                    } catch (NoSuchMethodException | IllegalAccessException | InvocationTargetException e) {
                        throw new RuntimeException(e);
                    }
                });

                // commit the offsets back to kafka
                consumer.commitSync();
            }

        } catch (WakeupException ex) {
            // awake from poll
        } catch (Exception ex) {
            logger.error("An unexpected error occurred!", ex);
        } finally {
            // gracefully shutdown the consumer!
            consumer.close();
            shutdownLatch.countDown();
        }
    }

    public void shutdown() throws InterruptedException {
        consumer.wakeup();
        shutdownLatch.await();
    }

    public static void main(String[] args) throws Exception {
        // load passed in properties
        String configPath = args.length > 0 ? args[0] : DEFAULT_CONFIG_FILE;
        final Properties cfg = new Properties();
        cfg.load(new FileInputStream(configPath));
        // get the topic to consumer from
        String kafkaTopic = args.length > 1 ? args[1] : DEFAULT_TOPIC;
        List<String> topics = Arrays.asList(kafkaTopic.split(","));

        // Start up our consumer thread
        TestConsumer bc = new TestConsumer(cfg, topics);
        Thread thread = new Thread(bc);
        thread.start();

        try {
            thread.join();
        } catch (InterruptedException e) {
            bc.shutdown();
        }
    }
}
