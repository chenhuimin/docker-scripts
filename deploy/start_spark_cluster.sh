#!/bin/bash

MASTER=-1
MASTER_IP=
NUM_REGISTERED_WORKERS=0
STARTEDCONTAINERS=

# starts the Spark/Shark master container
function start_master() {
    echo "starting master container"
    if [ "$DEBUG" -gt 0 ]; then
        echo docker run -d --dns $NAMESERVER_IP -h master${DOMAINNAME} --name master${DOMAINNAME} $VOLUME_MAP $1:$2
    fi
    MASTER=$(docker run -d --dns $NAMESERVER_IP -h master${DOMAINNAME} --name master${DOMAINNAME} $VOLUME_MAP $1:$2)

    if [ "$MASTER" = "" ]; then
        echo "error: could not start master container from image $1:$2"
        exit 1
    fi

    echo "started master container:      $MASTER"
    sleep 3
    MASTER_IP=$(docker logs $MASTER 2>&1 | egrep '^MASTER_IP=' | awk -F= '{print $2}' | tr -d -c "[:digit:] .")
    echo "MASTER_IP:                     $MASTER_IP"
    add_hostname master${DOMAINNAME} $MASTER_IP
}

# starts a number of Spark/Shark workers
function start_workers() {
    for i in `seq 1 $NUM_WORKERS`; do
        echo "starting worker container"
	hostname="worker${i}${DOMAINNAME}"
        if [ "$DEBUG" -gt 0 ]; then
	    echo docker run -d --dns $NAMESERVER_IP -h $hostname --name $hostname -e SPARK_MASTER_IP=master${DOMAINNAME} -e MASTER=spark://master${DOMAINNAME}:7077 $VOLUME_MAP $1:$2 ${MASTER_IP}
        fi
	WORKER=$(docker run -d --dns $NAMESERVER_IP -h $hostname --name $hostname -e SPARK_MASTER_IP=master${DOMAINNAME} -e MASTER=spark://master${DOMAINNAME}:7077 $VOLUME_MAP $1:$2 ${MASTER_IP})

        if [ "$WORKER" = "" ]; then
            echo "error: could not start worker container from image $1:$2"
            exit 1
        fi

	echo "started worker container:  $WORKER"
	sleep 3
	WORKER_IP=$(docker logs $WORKER 2>&1 | egrep '^WORKER_IP=' | awk -F= '{print $2}' | tr -d -c "[:digit:] .")
  add_hostname $hostname $WORKER_IP
    done
}

# prints out information on the cluster
function print_cluster_info() {
    BASEDIR=$(cd $(dirname $0); pwd)"/.."
    echo ""
    echo "***********************************************************************"
    echo "start shell via:            $1"
    echo ""
    echo "visit Spark WebUI at:       http://$MASTER_IP:8080/"
    echo "visit Hadoop Namenode at:   http://$MASTER_IP:50070"
    echo "ssh into master via:        ssh -i $BASEDIR/apache-hadoop-hdfs-precise/files/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${MASTER_IP}"
    echo ""
    echo "/data mapped:               $VOLUME_MAP"
    echo ""
    echo "kill master via:           docker kill $MASTER"
    echo "***********************************************************************"
    echo ""
    echo "to enable cluster name resolution add the following line to _the top_ of your host's /etc/resolv.conf:"
    echo "nameserver $NAMESERVER_IP"
    echo ""
    echo "Cleanup: docker rm -f $STARTEDCONTAINERS"
    echo ""
    docker exec nameserver${DOMAINNAME} cat /etc/dnsmasq.d/0hosts
}

function get_num_registered_workers() {
    if [[ "$SPARK_VERSION" == "0.7.3" ]]; then
        DATA=$( curl --noproxy -s http://$MASTER_IP:8080/?format=json | tr -d '\n' | sed s/\"/\\\\\"/g)
    else
	# Docker on Mac uses tinycore Linux with busybox which has a limited version wget (?)
	echo $(uname -a) | grep "Linux boot2docker" > /dev/null
	if [[ "$?" == "0" ]]; then
		DATA=$( wget -Y off -q -O - http://$MASTER_IP:8080/json | tr -d '\n' | sed s/\"/\\\\\"/g)
	else
        	DATA=$( wget --no-proxy -q -O - http://$MASTER_IP:8080/json | tr -d '\n' | sed s/\"/\\\\\"/g)
	fi
    fi
    NUM_REGISTERED_WORKERS=$(python -c "import json; data = \"$DATA\"; value = json.loads(data); print len(value['workers'])")
}

function wait_for_master {
    if [[ "$SPARK_VERSION" == "0.7.3" ]]; then
        query_string="INFO HttpServer: akka://sparkMaster/user/HttpServer started"
    elif [[ "$SPARK_VERSION" == "latest" ]]; then
        query_string="MasterWebUI: Started MasterWebUI"
    else
        query_string="MasterWebUI: Started Master web UI"
    fi
    echo -n "waiting for master "
    docker logs $MASTER | grep "$query_string" > /dev/null
    until [ "$?" -eq 0 ]; do
        echo -n "."
        sleep 1
        docker logs $MASTER | grep "$query_string" > /dev/null;
    done
    echo ""
    echo -n "waiting for nameserver to find master "
    check_hostname result master${DOMAINNAME} "$MASTER_IP"
    until [ "$result" -eq 0 ]; do
        echo -n "."
        sleep 1
        check_hostname result master${DOMAINNAME} "$MASTER_IP"
    done
    echo ""
    sleep 3
}
