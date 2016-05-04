FROM java:8-jdk-alpine

ENV WILDFLY_VERSION="10.0.0.Final" \
    WILDFLY_UID="1000" \
    WILDFLY_GID="1000" \
    WILDFLY_USER="wildfly" \
    WILDFLY_GROUP="wildfly" \
    S6_VERSION="1.17.1.1" \
    JBOSS_HOME="/opt/jboss/wildfly" \
    JAVA_HOME="/usr/lib/jvm/default-jvm"

ONBUILD ADD jboss-cli /opt/jboss-cli/
ONBUILD RUN /build.sh jboss-cli-only

# Expose the ports we're interested in
EXPOSE 8080 8009 9990

COPY scripts/10-wildfly-dirfix /etc/fix-attrs.d/10-wildfly-dirfix
COPY scripts/build.sh /build.sh
COPY scripts/run.sh /run.sh
RUN chmod 755 build.sh run.sh
RUN /build.sh

ADD http.war /opt/jboss/wildfly/standalone/deployments/

ENTRYPOINT [ "/init" ]
CMD ["/run.sh"]
