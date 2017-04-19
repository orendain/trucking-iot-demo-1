#!/usr/bin/env bash

projectDir="$(cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd)"
cd $projectDir

git clone https://github.com/orendain/trucking-iot trucking-iot-helper
cd trucking-iot-helper
git checkout dev

cd $projectDir
scripts/build-topology.sh
