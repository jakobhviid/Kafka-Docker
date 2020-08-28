FROM ubuntu:18.04

LABEL MAINTAINER="Oliver Marco van Komen"

ENV KAFKA_HOME=/opt/kafka

RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-11-jre-headless && \
    apt-get install -y jq curl

# Copy scripts
COPY scripts /tmp/
RUN chmod +x /tmp/*.sh && \
    mv /tmp/*.sh /usr/bin && \
    rm -rf /tmp/*.sh

# Install kafka
COPY ./kafka_2.12-2.4.0.tgz /opt/
RUN cd /opt && \
    tar -xzf kafka_2.12-2.4.0.tgz && \
    mv kafka_2.12-2.4.0 ${KAFKA_HOME} && \
    rm -rf /opt/*.tgz

# Copy server files
COPY server_configurations/* ${KAFKA_HOME}/config/

RUN mkdir /ssl/ && mkdir /ssl/healthcheck && mkdir /sasl

EXPOSE 9091 9092 9093 9094 9095 9096

HEALTHCHECK --interval=75s --timeout=60s --start-period=25s --retries=2 CMD [ "healthcheck.sh" ]

ENV KAFKA_DATA_HOME=/data/kafka
ENV KAFKA_SSL_HOME=/ssl
ENV KAFKA_SASL_HOME=/sasl
ENV KAFKA_LOGS=${KAFKA_HOME}/logs

VOLUME [ "${KAFKA_DATA_HOME}", "${KAFKA_SSL_HOME}" ]

WORKDIR ${KAFKA_HOME}

CMD [ "start.sh" ]