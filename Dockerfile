FROM ubuntu:18.04

ENV KAFKA_HOME=/opt/kafka
ENV KAFKA_DATA_HOME=/data/kafka
ENV KAFKA_SSL_HOME=/ssl

RUN apt update && \
    apt install -y --no-install-recommends openjdk-11-jre-headless && \
    apt install -y jq curl

# Copy necessary scripts + configuration
COPY scripts server_setup/server.properties /tmp/
RUN chmod +x /tmp/*.sh && \
    mv /tmp/*.sh /usr/bin && \
    rm -rf /tmp/*.sh

# Install kafka
COPY ./kafka_2.12-2.4.0.tgz /opt/
RUN cd /opt && \
    tar -xzf kafka_2.12-2.4.0.tgz && \
    mv kafka_2.12-2.4.0 ${KAFKA_HOME} && \
    rm -rf /opt/*.tar && \
    mv /tmp/server.properties ${KAFKA_HOME}/config/server.properties

RUN mkdir /ssl/

EXPOSE 9092 9093

HEALTHCHECK --interval=75s --timeout=35s --start-period=15s --retries=2 CMD [ "healthcheck.sh" ]

VOLUME [ ${KAFKA_DATA_HOME}, ${KAFKA_SSL_HOME} ]

WORKDIR ${KAFKA_HOME}

CMD [ "start.sh" ]