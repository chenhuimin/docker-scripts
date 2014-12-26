# Spark
FROM omriiluz/spark-base:1.2
MAINTAINER omri@iluz.net

# Expose TCP ports 7077 8080
EXPOSE 7077 8080

ADD files /root/spark_master_files

CMD ["/root/spark_master_files/default_cmd"]
