#!/usr/bin/env bash
# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

ARCHFLAG=""
if [ ${1} = "64" ]; then
    ARCHFLAG="64/"
fi

CACHE="${BOOTSTRAP_CACHE:-bootstrap-cache}"

find ${CACHE}

wget -O- get.pharo.org/${ARCHFLAG}vm70 | bash
					
IMAGE_ARCHIVE=$(find ${CACHE} -name Pharo7.0-bootstrap-${1}bit-*.zip)
unzip $IMAGE_ARCHIVE
IMAGE_FILE=$(find . -name Pharo7.0-bootstrap-${1}bit-*.image)

HERMES_ARCHIVE=$(find ${CACHE} -name Pharo7.0-hermesPackages-${1}bit-*.zip)
unzip $HERMES_ARCHIVE

RPACKAGE_ARCHIVE=$(find ${CACHE} -name Pharo7.0-rpackage-${1}bit-*.zip)
unzip $RPACKAGE_ARCHIVE

mv $IMAGE_FILE bootstrap.image

export PHARO_CI_TESTING_ENVIRONMENT=1
			
#Initializing the Image
./pharo bootstrap.image
#Adding packages removed from the bootstrap
./pharo bootstrap.image loadHermes Hermes-Extensions.hermes --save
./pharo bootstrap.image loadHermes Collections-Atomic.hermes AST-Core.hermes Collections-Arithmetic.hermes 

#Initializing the package manager
./pharo bootstrap.image initializePackages --packages=packagesKernel.txt --protocols=protocolsKernel.txt --save

#Loading Tests
./pharo bootstrap.image loadHermes SUnit-Core.hermes JenkinsTools-Core.hermes JenkinsTools-Core.hermes SUnit-Tests.hermes --save --no-fail-on-undeclared --on-duplication=ignore

#Running tests.
./pharo bootstrap.image test --junit-xml-output SUnit-Core SUnit-Tests	
