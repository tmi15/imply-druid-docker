#!/bin/bash
set -e

# general options
CONF_DIR="conf"
ENVIRONMENT="druid"
DEBUG=1

# class paths
CP_COMMON="conf/druid/_common"
CP_LIB="dist/druid/lib/*"
CP_EXTRA=""

# class
CLASS_DRUID="io.druid.cli.Main"

JAVA_OPTIONS="$CONF_DIR/$ENVIRONMENT/$1/jvm.config"
CLASS_PATH="$CP_COMMON:$CONF_DIR/$ENVIRONMENT/$1:$CP_LIB:$CP_EXTRA"
if [ -z ${DEBUG+x} ] ; then
	echo $JAVA_OPTIONS
	echo $CLASS_PATH
fi

exec java $(cat $JAVA_OPTIONS | xargs) $JAVA_EXTRA_OPTIONS -cp $CLASS_PATH $CLASS_DRUID server $1
