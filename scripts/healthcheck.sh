#!/bin/bash

# Test kafka runs in container correctly
kafkaProcess=$(ps -x | grep java | grep kafka)

# If kafkaProcess is not empty
if ! [[ -z "$kafkaProcess" ]]; then
    # Check logic. Healthcheck will time out if server is not available.
    topicName="TEST-HEALTHCHECK-BROKER-$KAFKA_BROKER_ID"
    KAFKA_HEALTHCHECK_PORT=${KAFKA_HEALTHCHECK_PORT:-9092}
    
    /opt/kafka/bin/kafka-topics.sh --create --topic $topicName --bootstrap-server localhost:$KAFKA_HEALTHCHECK_PORT --partitions 1 --replication-factor 1

    # If somehow the topic already exists it will throw an error when creating, but if this checks goes through that means the server is still operating fine and will therefore not be considered unhealthy
    topic=$(/opt/kafka/bin/kafka-topics.sh --list --topic $topicName --bootstrap-server localhost:$KAFKA_HEALTHCHECK_PORT | grep "$topicName")

    # If topic is empty
    if [[ -z "$topic" ]]; then
        echo " ERROR Could not find created topic in list "
        exit 1
    fi

    # Delete topic
    /opt/kafka/bin/kafka-topics.sh --delete --topic $topicName --bootstrap-server localhost:$KAFKA_HEALTHCHECK_PORT

    echo " OK "
    exit 0
fi

echo " KAFKA SERVER NOT RUNNING PROPERLY "
exit 1
