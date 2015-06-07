#!/usr/bin/env bash
export SCALA_HOME=/opt/scala-2.10.5
export SPARK_HOME=__SPARK_HOME__
[ -z $SPARK_WORKER_CORES ] && export SPARK_WORKER_CORES=1
[ -z $SPARK_MEM ] && export SPARK_MEM=800m
[ -z $SPARK_WORKER_MEMORY ] && export SPARK_WORKER_MEMORY=1500m
[ -z $SPARK_MASTER_MEM ] && export SPARK_MASTER_MEM=1500m
[ -z $SPARK_MASTER_IP ] && export SPARK_MASTER_IP=__MASTER__
export HADOOP_HOME="/etc/hadoop"
[ -z $MASTER ] && export MASTER="spark://__MASTER__:7077"
export SPARK_LOCAL_DIR=/tmp/spark
#SPARK_JAVA_OPTS="-Dspark.local.dir=/tmp/spark "
#SPARK_JAVA_OPTS+=" -Dspark.akka.logLifecycleEvents=true "
#SPARK_JAVA_OPTS+="-Dspark.kryoserializer.buffer.mb=10 "
#SPARK_JAVA_OPTS+="-verbose:gc -XX:-PrintGCDetails -XX:+PrintGCTimeStamps "
#export SPARK_JAVA_OPTS
#SPARK_DAEMON_JAVA_OPTS+=" -Dspark.akka.logLifecycleEvents=true "
#export SPARK_DAEMON_JAVA_OPTS
export JAVA_HOME=__JAVA_HOME__
