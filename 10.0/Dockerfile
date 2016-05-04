FROM java:8-jdk-alpine

ENV WILDFLY_VERSION="10.0.0.Final" \
    WILDFLY_UID="1000" \
    WILDFLY_GID="1000" \
    WILDFLY_USER="wildfly" \
    WILDFLY_GROUP="wildfly" \
    S6_VERSION="1.17.1.1" \
    JBOSS_HOME="/opt/wildfly" \
    JAVA_HOME="/usr/lib/jvm/default-jvm" \
	JOLOKIA_DIR="/opt/jolokia" \
	JOLOKIA_VERSION="1.3.3"

ONBUILD ADD jboss-cli /opt/jboss-cli/
ONBUILD ADD jboss-modules $JBOSS_HOME/modules/
ONBUILD ADD jboss-deployments $JBOSS_HOME/standalone/deployments/
ONBUILD RUN /build.sh jboss-cli-only

# Expose the ports we're interested in
EXPOSE 8080 8009 9990 8778

ADD scripts /
RUN chmod 755 /build.sh /run.sh /jolokia_opts.sh
RUN /build.sh

ENTRYPOINT [ "/init" ]
CMD ["/run.sh"]
