FROM java:8-jdk-alpine

ENV WILDFLY_VERSION="10.0.0.Final" \
    WILDFLY_UID="1000" \
    WILDFLY_GID="1000" \
    WILDFLY_USER="wildfly" \
    WILDFLY_GROUP="wildfly" \
    S6_VERSION="1.17.2.0" \
    JBOSS_HOME="/opt/wildfly" \
    JOLOKIA_VERSION="1.3.3" \
    JOLOKIA_ENABLED="true"

ONBUILD ADD jboss-cli /opt/jboss-cli/
ONBUILD ADD jboss-modules $JBOSS_HOME/modules/
ONBUILD ADD jboss-deployments $JBOSS_HOME/standalone/deployments/
ONBUILD RUN /build.sh jboss-cli-only

# Expose the ports we're interested in
EXPOSE 8080 8009 9990

# Put most of the "in-OS" actions into a build script so docker doesn't
# create 20+ layers for an image that doesn't change often
ADD scripts /
RUN chmod 755 /build.sh /run.sh
RUN /build.sh

ADD jolokia-web.xml $JBOSS_HOME/standalone/deployments/jolokia.war/WEB-INF/web.xml

ENTRYPOINT [ "/init" ]
CMD ["/run.sh"]
