#!/usr/bin/env bash

projectDir="$(cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd)"
cd $projectDir/trucking-iot-helper

# Start web application
sbt webApplicationBackend/run
