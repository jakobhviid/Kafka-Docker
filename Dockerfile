FROM ubuntu:18.04

ENV KAFKA_HOME=/opt/kafka

RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-8-jre-headless && \
    apt-get install -y jq

# Copy necessary scripts + configuration
COPY scripts server.properties /tmp/
RUN chmod +x /tmp/*.sh && \
    mv /tmp/*.sh /usr/bin && \
    rm -rf /tmp/*.sh

# Install kafka
# ADD https://archive.apache.org/dist/kafka/2.4.0/kafka_2.12-2.4.0.tgz /opt/
COPY ./kafka_2.12-2.4.0.tar /opt/
RUN cd /opt && \
    tar -xf kafka_2.12-2.4.0.tar && \
    mv kafka_2.12-2.4.0 kafka && \
    rm -rf /opt/*.tar && \
    mv /tmp/server.properties /opt/kafka/config/server.properties && \
    mkdir /data && mkdir /data/kafka

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "healthcheck.sh" ]

CMD [ "start.sh" ]

