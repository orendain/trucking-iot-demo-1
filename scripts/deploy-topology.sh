#!/usr/bin/env bash

projectDir="$(cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd)"

storm jar $projectDir/trucking-storm-topology-java/target/trucking-storm-topology-java-0.3.2.jar com.orendainx.hortonworks.trucking.storm.java.topologies.KafkaToKafka
