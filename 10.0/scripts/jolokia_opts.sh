#!/usr/bin/env bash

dir=${JOLOKIA_DIR:-/opt/jolokia}
if [ -z ${JOLOKIA_OFF+x} ]; then
   opts="-javaagent:$dir/jolokia.jar"
   config=${JOLOKIA_CONFIG:-$dir/jolokia.properties}
   if [ -f "$JOLOKIA_CONFIG" ]; then
      # Configuration takes precedence
      opts="${opts}=config=${JOLOKIA_CONFIG}"
   else
     # Direct options only if no configuration is found
     opts="${opts}=host=${JOLOKIA_HOST:-*},agentId=${JOLOKIA_ID:-$HOSTNAME}"
     if [ -n "$JOLOKIA_PORT" ]; then
        opts="${opts},port=${JOLOKIA_PORT}"
     fi
     if [ -n "$JOLOKIA_USER" ]; then
        opts="${opts},user=${JOLOKIA_USER}"
     fi
     if [ -n "$JOLOKIA_PASSWORD" ]; then
        opts="${opts},password=${JOLOKIA_PASSWORD}"
     fi

     # Integration of 3rd party environments
     if [ -n "$JOLOKIA_AUTH_OPENSHIFT" ]; then
        opts="${opts},authMode=delegate,authUrl=${JOLOKIA_AUTH_OPENSHIFT%/}/users/~,authPrincipalSpec=json:metadata/user,authIgnoreCerts=true"
     fi

     # Add extra opts to the end
     if [ -n "$JOLOKIA_OPTS" ]; then
        opts="${opts},${JOLOKIA_OPTS}"
     fi
   fi
   echo $opts
fi