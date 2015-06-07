#!/bin/bash
. /opt/spark-1.3.1/conf/spark-env.sh
${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.worker.Worker $MASTER
