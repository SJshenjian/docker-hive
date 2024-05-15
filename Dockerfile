FROM bde2020/hadoop-base:2.0.0-hadoop3.2.1-java8

MAINTAINER Yiannis Mouchakis <gmouchakis@iit.demokritos.gr>
MAINTAINER Ivan Ermilov <ivan.s.ermilov@gmail.com>
MAINTAINER Jian Shen <SJshenjian@outlook.com>

# Allow buildtime config of HIVE_VERSION
ARG HIVE_VERSION
# Set HIVE_VERSION from arg if provided at build, env if provided at run, or default
# https://docs.docker.com/engine/reference/builder/#using-arg-variables
# https://docs.docker.com/engine/reference/builder/#environment-replacement
ENV HIVE_VERSION=${HIVE_VERSION:-3.1.3}

ENV HIVE_HOME /opt/hive
ENV PATH $HIVE_HOME/bin:$PATH
ENV HADOOP_HOME /opt/hadoop-$HADOOP_VERSION

WORKDIR /opt

RUN sed -i 's/^.*$/deb http:\/\/mirrors.tuna.tsinghua.edu.cn\/debian\/ buster main\ndeb-src http:\/\/mirrors.tuna.tsinghua.edu.cn\/debian\/ buster main\ndeb http:\/\/mirrors.tuna.tsinghua.edu.cn\/debian-security\/ buster\/updates main\ndeb-src http:\/\/mirrors.tuna.tsinghua.edu.cn\/debian-security\/ buster\/updates main/g' /etc/apt/sources.list

#Install Hive and PostgreSQL JDBC
#Install Hive and PostgreSQL JDBC
RUN apt-get update && apt-get install -y wget procps && \
	wget https://mirrors.tuna.tsinghua.edu.cn/apache/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz && \
	tar -xzvf apache-hive-3.1.3-bin.tar.gz && \
	mv apache-hive-3.1.3-bin hive
RUN wget https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar -O $HIVE_HOME/lib/postgresql-jdbc.jar && \
	rm apache-hive-3.1.3-bin.tar.gz && \
	apt-get --purge remove -y wget && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*


#Spark should be compiled with Hive to be able to use it
#hive-site.xml should be copied to $SPARK_HOME/conf folder

#Custom configuration goes here
ADD conf/hive-site.xml $HIVE_HOME/conf
ADD conf/beeline-log4j2.properties $HIVE_HOME/conf
ADD conf/hive-env.sh $HIVE_HOME/conf
ADD conf/hive-exec-log4j2.properties $HIVE_HOME/conf
ADD conf/hive-log4j2.properties $HIVE_HOME/conf
ADD conf/ivysettings.xml $HIVE_HOME/conf
ADD conf/llap-daemon-log4j2.properties $HIVE_HOME/conf

COPY startup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/startup.sh

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# solve log version conflict
RUN cp /opt/hadoop-3.2.1/share/hadoop/common/lib/guava-27.0-jre.jar /opt/hive/lib/
RUN rm -rf /opt/hive/lib/guava-19.0.jar

EXPOSE 10000
EXPOSE 10002

ENTRYPOINT ["entrypoint.sh"]
CMD startup.sh
