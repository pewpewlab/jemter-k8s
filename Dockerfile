FROM alpine:3.20

ARG JMETER_VERSION=5.6.3

RUN apk add --no-cache bash ca-certificates curl openjdk17-jre-headless tar \
    && mkdir -p /opt \
    && curl -fsSL "https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz" \
    | tar -xz -C /opt \
    && ln -s "/opt/apache-jmeter-${JMETER_VERSION}" /opt/jmeter \
    && addgroup -S jmeter \
    && adduser -S -G jmeter jmeter \
    && mkdir -p /tests /results \
    && chown -R jmeter:jmeter /tests /results

ENV PATH="/opt/jmeter/bin:${PATH}"

COPY run-jmeter.sh /opt/run-jmeter.sh
RUN chmod +x /opt/run-jmeter.sh

USER jmeter
WORKDIR /work

ENTRYPOINT ["/opt/run-jmeter.sh"]
