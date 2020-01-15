FROM ubuntu:18.04

ENV KAFKA_HOME=/opt/kafka

RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-8-jre-headless && \
    apt-get install -y jq

# Test if mirror is working and use other mirrors if the optimal ones are down
ADD https://archive.apache.org/dist/kafka/2.4.0/kafka_2.12-2.4.0.tgz /opt/

# Install kafka
RUN cd /opt && \
    tar -xzf kafka_2.12-2.4.0.tgz && \
    mv kafka_2.12-2.4.0 kafka && \
    rm -rf /opt/*.tgz && \
    mkdir ${KAFKA_HOME}/data

# Setup necessary scripts 
COPY scripts /tmp/
RUN chmod +x /tmp/*.sh && \
    mv /tmp/*.sh /usr/bin && \
    rm -rf /tmp/*

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "healthcheck.sh" ]

CMD [ "start.sh" ]

