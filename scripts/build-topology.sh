#!/usr/bin/env bash

projectDir="$(cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd)"

cd $projectDir/trucking-commons
mvn scala:compile

cd $projectDir
mvn install
