#!/bin/bash

# Test kafka runs in container correctly
kafkaProcess=$(ps -x | grep java | grep kafka)

# If kafkaProcess is not empty
if ! [[ -z "$kafkaProcess" ]]; then
    # Check logic. Healthcheck will time out if server is not available.
    topicName="TEST-HEALTHCHECK-BROKER-$KAFKA_BROKER_ID"
    /opt/kafka/bin/kafka-topics.sh --create --topic $topicName --bootstrap-server localhost:55555 --partitions 1 --replication-factor 1

    # If somehow the topic already exists it will throw an error when creating, but if this checks goes through that means the server is still operating fine and will therefore not be considered unhealthy
    topic=$(/opt/kafka/bin/kafka-topics.sh --list --topic $topicName --bootstrap-server localhost:55555 | grep "$topicName")

    # If topic is empty
    if [[ -z "$topic" ]]; then
        echo " ERROR Could not find created topic in list "
        exit 1
    fi

    # Delete topic
    /opt/kafka/bin/kafka-topics.sh --delete --topic $topicName --bootstrap-server localhost:55555

    echo " OK "
    exit 0
fi

echo " KAFKA SERVER NOT RUNNING PROPERLY "
exit 1
