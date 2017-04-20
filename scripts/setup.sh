#!/usr/bin/env bash

hostname="sandbox.hortonworks.com"
ambariClusterName="Sandbox"
ambariUser="admin"
ambariPass="admin"

projectDir="$(cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd)"
cd $projectDir

git clone https://github.com/orendain/trucking-iot trucking-iot-helper
cd trucking-iot-helper
git checkout dev


#
# Note: This script assumes that Ambari is up and running at this point.
#

echo "Setting delete.topic.enable to true via Ambari"
/var/lib/ambari-server/resources/scripts/configs.py -u $ambariUser -p $ambariPass --action=set --host=$hostname --cluster=$ambariClusterName --config-type=kafka-broker -k delete.topic.enable -v true

echo "Restarting Kafka via Ambari"
curl -u $ambariUser:$ambariPass -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context": "Stop Kafka"}, "ServiceInfo": {"state": "INSTALLED"}}' http://$hostname:8080/api/v1/clusters/$ambariClusterName/services/KAFKA
sleep 10
curl -u $ambariUser:$ambariPass -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context": "Start Kafka"}, "ServiceInfo": {"state": "STARTED"}}' http://$hostname:8080/api/v1/clusters/$ambariClusterName/services/KAFKA

echo "Checking for SBT and maven, installing if missing"
curl https://bintray.com/sbt/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
yum -y install sbt-0.13.13.1-1 apache-maven

scripts/create-kafka-topics.sh

cd $projectDir
scripts/build-topology.sh

