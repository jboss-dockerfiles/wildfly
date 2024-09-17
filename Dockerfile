# By default, build on JDK 11 on UBI 9.
ARG jdk=21
# Red Hat UBI 9 (ubi9-minimal) should be used on JDK 11 and later.
ARG dist=ubi9-minimal
FROM eclipse-temurin:${jdk}-${dist}

LABEL org.opencontainers.image.source=https://github.com/jboss-dockerfiles/wildfly org.opencontainers.image.title=wildfly org.opencontainers.imag.url=https://github.com/jboss-dockerfiles/wildfly org.opencontainers.image.vendor=WildFly

# Starting on jdk 17 eclipse-temurin is based on ubi9-minimal version 9.3 
#   that doesn't includes shadow-utils package that provides groupadd & useradd commands
# Conditional RUN: IF no groupadd AND microdnf THEN: update, install shadow-utils, clean
RUN if ! [ -x "$(command -v groupadd)" ] && [ -x "$(command -v microdnf)" ]; then microdnf update -y && microdnf install --best --nodocs -y shadow-utils && microdnf clean all; fi

WORKDIR /opt/jboss

RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 33.0.1.Final
ENV WILDFLY_SHA1 943ec801bf65bb42de27ef78c85d325180dcab0d
ENV JBOSS_HOME /opt/jboss/wildfly

USER root

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl -L -O https://github.com/wildfly/wildfly/releases/download/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER jboss

# Expose the ports in which we're interested
EXPOSE 8080

# Set the default command to run on boot
# This will boot WildFly in standalone mode and bind to all interfaces
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]
