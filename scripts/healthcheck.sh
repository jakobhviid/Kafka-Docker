#!/bin/bash

# Test kafka runs in container correctly
kafkaProcess=$(ps -x | grep java | grep kafka)

# If kafkaProcess is not empty
if ! [[ -z "$kafkaProcess" ]]; then
    # Check logic. Healthcheck will time out if server is not available.
    topicName="HEALTHCHECK-BROKER-$KAFKA_BROKER_ID"
    KAFKA_HEALTHCHECK_PORT=${KAFKA_HEALTHCHECK_PORT:-9092}
    
    # Fetch topic information
    topic=$(/opt/kafka/bin/kafka-topics.sh --list --topic $topicName --bootstrap-server localhost:$KAFKA_HEALTHCHECK_PORT | grep "$topicName")

    # If topic is empty, should only happen when starting a new kafka server
    if [[ -z "$topic" ]]; then
		#Create new topic
		/opt/kafka/bin/kafka-topics.sh --create --topic $topicName --bootstrap-server localhost:$KAFKA_HEALTHCHECK_PORT --partitions 1 --replication-factor 1
		
		# Refetch topic information
		topic=$(/opt/kafka/bin/kafka-topics.sh --list --topic $topicName --bootstrap-server localhost:$KAFKA_HEALTHCHECK_PORT | grep "$topicName")
		
		# If topic is still empty
		if [[ -z "$topic" ]]; then
			echo " ERROR Could not find healthcheck topic in list "
			exit 1
		fi
    fi

    echo " OK "
    exit 0
fi

echo " KAFKA SERVER NOT RUNNING PROPERLY "
exit 1
