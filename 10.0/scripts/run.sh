#!/usr/bin/env bash

echo "Process Environment:"
echo "========================================================================="
env | sort
echo "========================================================================="

# eliminate potential statup delays due to broken /dev/random
ADDL_JAVA_OPTS="$ADDL_JAVA_OPTS -Djava.security.egd=file:/dev/./urandom";

# set logging options
ADDL_JAVA_OPTS="$ADDL_JAVA_OPTS -Dlogging.root.level=${LOG_ROOT_LEVEL:-DEBUG}"
ADDL_JAVA_OPTS="$ADDL_JAVA_OPTS -Dlogging.file.level=${LOG_FILE_LEVEL:-INFO} -Dlogging.file.formatter=${LOG_FILE_FORMATTER:-PATTERN}"
ADDL_JAVA_OPTS="$ADDL_JAVA_OPTS -Dlogging.console.level=${LOG_CONSOLE_LEVEL:-INFO} -Dlogging.console.formatter=${LOG_CONSOLE_FORMATTER:-COLOR-PATTERN}"
ADDL_JAVA_OPTS="$ADDL_JAVA_OPTS -Dlogging.socket.enabled=${LOG_SOCKET_ENABLED:-false} -Dlogging.socket.level=${LOG_SOCKET_LEVEL:-INFO} -Dlogging.socket.formatter=${LOG_SOCKET_FORMATTER:-JSON} -Dlogging.socket.hostname=${LOG_SOCKET_HOSTNAME:-localhost} -Dlogging.socket.port=${LOG_SOCKET_PORT:-8000}"


if [[ ${CONFIG_FILE} ]] && [[ ${CONFIG_FILE} == *ha.xml ]]; then
  if [[ -z $GOSSIP_ROUTERS ]]; then
    echo "If you are using an HA configuration you also have to define a 'GOSSIP_ROUTERS' variabel that contains the connection string (e.g. GOSSIP_ROUTERS=\"10.20.120.2[12001],10.20.120.2[12001]\""
    exit 1
  else
    # add the gossip routers
    ADDL_JAVA_OPTS="$ADDL_JAVA_OPTS -Djgroups.gossip_router_hosts=$GOSSIP_ROUTERS"
  fi
fi

if [[ $JOLOKIA_ENABLED == "true" ]]; then
  echo "Jolokia enabled!"
  touch $JBOSS_HOME/standalone/deployments/jolokia.war.dodeploy
else
  touch $JBOSS_HOME/standalone/deployments/jolokia.war.skipdeploy
fi

if [ "x$JBOSS_MODULES_SYSTEM_PKGS" = "x" ]; then
   JBOSS_MODULES_SYSTEM_PKGS="org.jboss.byteman"
fi

if [ "x$JAVA_OPTS" = "x" ]; then
   JAVA_OPTS="-Xms64m -Xmx768m -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m -Djava.net.preferIPv4Stack=true"
   JAVA_OPTS="$JAVA_OPTS -Djboss.modules.system.pkgs=$JBOSS_MODULES_SYSTEM_PKGS -Djava.awt.headless=true"
else
   echo "JAVA_OPTS already set in environment; overriding default settings with values: $JAVA_OPTS"
fi

export JAVA_OPTS="$JAVA_OPTS $ADDL_JAVA_OPTS"

exec s6-applyuidgid -u 1000 -g 1000 $JBOSS_HOME/bin/standalone.sh -Djboss.node.name=${NODE_NAME:-$HOSTNAME} -b $(hostname -i) -bmanagement $(hostname -i) -c ${CONFIG_FILE:-standalone.xml}
