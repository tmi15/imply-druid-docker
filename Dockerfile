FROM ubuntu:16.04

# Prepare OS
COPY setup-os.sh /root
RUN /root/setup-os.sh

# Copy package from build directory
ENV IMPLY_DRUID_VERSION 2.7.5
ENV DRUID_HOME /opt/imply
ENV EXTRA_ARGS="-javaagent:${DRUID_HOME}/dist/druid/lib/jmx_prometheus_javaagent-0.10.jar=9010:/etc/jmx_exporter/jmx_exporter.yaml "

# Download Imply package
RUN wget -q --no-check-certificate https://static.imply.io/release/imply-${IMPLY_DRUID_VERSION}.tar.gz -O /opt/imply-${IMPLY_DRUID_VERSION}.tar.gz

# Unpackage druid
RUN tar xzf /opt/imply-${IMPLY_DRUID_VERSION}.tar.gz -C /opt
RUN mkdir -p /mnt/imply/var && ln -snf /mnt/imply/var /opt/imply-${IMPLY_DRUID_VERSION}/var
RUN ln -snf /opt/imply-${IMPLY_DRUID_VERSION} /opt/imply

# Cleanup download
RUN rm /opt/imply-${IMPLY_DRUID_VERSION}.tar.gz

# Fix script from imply
ADD imply-ui ${DRUID_HOME}/dist/imply-ui/imply-ui

############################ STANDALONE VERSION #########################

#EXPOSE 1527 2181 8081 8082 8083 8090 8091 8100 8101 8102 8103 8104 8105 8106 8107 8108 8109 8110 8200 9095

#EXPOSE 9010

#WORKDIR /opt/imply-$IMPLY_DRUID_VERSION

## The following is used for standalone druid install (non-cluster)
#CMD ["bin/supervise", "-c", "conf/supervise/quickstart.conf"]

############################ CLUSTERED VERSION ##########################
## Everything below this line is used for clustered druid install

ADD entrypoint.sh ${DRUID_HOME}/entrypoint.sh

# change permissions
RUN chmod +x ${DRUID_HOME}/entrypoint.sh

# Pull dependencies
RUN   cd ${DRUID_HOME} \
      && java \
      -cp "${DRUID_HOME}/dist/druid/lib/*" \
      -Ddruid.extensions.directory="${DRUID_HOME}/dist/druid/extensions" \
      -Ddruid.extensions.hadoopDependenciesDir="${DRUID_HOME}/dist/druid/hadoop-dependencies" \
      io.druid.cli.Main tools pull-deps \
      --no-default-hadoop \
      --defaultVersion "0.12.2" \
      -c "io.druid.extensions.contrib:druid-parquet-extensions:0.12.2"

RUN mkdir -p ${DRUID_HOME}/var/tmp

RUN chmod -R a+rwx ${DRUID_HOME}/var

VOLUME ${DRUID_HOME}/var

ADD _common ${DRUID_HOME}/conf/druid/_common
ADD middleManager ${DRUID_HOME}/conf/druid/middleManager
ADD broker ${DRUID_HOME}/conf/druid/broker
ADD historical ${DRUID_HOME}/conf/druid/historical
ADD overlord ${DRUID_HOME}/conf/druid/overlord
ADD coordinator ${DRUID_HOME}/conf/druid/coordinator
ADD pivot ${DRUID_HOME}/conf/pivot
ADD druid-google-extensions ${DRUID_HOME}/dist/druid/extensions/druid-google-extensions

EXPOSE 8081 8082 8083 8084 8088 8090 8091 8092 8100-8110 8200 9095

EXPOSE 9010

RUN mkdir -p /etc/jmx_exporter

ADD ./jmx_exporter.yaml /etc/jmx_exporter
ADD ./libs/* ${DRUID_HOME}/dist/druid/lib/

WORKDIR ${DRUID_HOME}
ENTRYPOINT ["/opt/imply/entrypoint.sh"]

