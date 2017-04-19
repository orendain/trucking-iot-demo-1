#!/usr/bin/env bash

projectDir="$(cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd)"
cd $projectDir

git clone https://github.com/orendain/trucking-iot trucking-iot-helper
cd trucking-iot-helper
git checkout dev


#
# Note: This script assumes that Ambari is up and running at this point.
# It also assumes an Ambari username/pass of admin/admin and that it's running on local port 8080 with hostname "sandbox.hortonworks.com"
#

echo "Setting delete.topic.enable to true via Ambari"
/var/lib/ambari-server/resources/scripts/configs.py -u admin -p admin --action=set --host=sandbox.hortonworks.com --cluster=Sandbox --config-type=kafka-broker -k delete.topic.enable -v true

echo "Restarting Kafka via Ambari"
curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context": "Stop Kafka"}, "ServiceInfo": {"state": "INSTALLED"}}' http://sandbox.hortonworks.com:8080/api/v1/clusters/Sandbox/services/KAFKA
sleep 10
curl -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context": "Start Kafka"}, "ServiceInfo": {"state": "STARTED"}}' http://sandbox.hortonworks.com:8080/api/v1/clusters/Sandbox/services/KAFKA

echo "Checking for SBT, installing if missing"
curl https://bintray.com/sbt/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
yum -y install sbt-0.13.13.1-1

echo "Checking for Maven, installing if missing"
wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
yum install -y apache-maven

scripts/create-kafka-topics.sh

cd $projectDir
scripts/build-topology.sh
