#!/usr/bin/env bash

scriptDir="$(cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd)"

cd $scriptDir/trucking-commons
mvn scala:compile

cd $scriptDir
mvn install
