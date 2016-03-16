FROM jinweilin/java:8

RUN cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime \
		&& echo 'Asia/Taipei' > /etc/timezone \
    && date \
		&& sed -e 's;UTC=yes;UTC=no;' -i /etc/default/rcS \
    && groupadd -r jboss -g 1000 \
    && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss \
    && chmod 755 /opt/jboss \
    && apt-get update \
		&& apt-get install -y curl \
		&& mkdir -p "/home/art" \
		&& chown -R jboss:jboss /home/art

WORKDIR /opt/jboss
USER jboss

RUN echo $HOME

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 10.0.0.Final
ENV WILDFLY_SHA1 c0dd7552c5207b0d116a9c25eb94d10b4f375549
ENV JBOSS_HOME /opt/jboss/wildfly

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && mkdir -p wildfly/standalone/logs \
    && /opt/jboss/wildfly/bin/add-user.sh admin Passw0rd --silent

COPY edb /opt/jboss/wildfly/modules/system/layers/base/com/edb
COPY ibm /opt/jboss/wildfly/modules/system/layers/base/com/ibm

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

# Expose the ports we're interested in
EXPOSE 8080

VOLUME ["/opt/jboss/wildfly/standalone/log","/opt/jboss/wildfly/standalone/deployments","/home/art"]

CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]