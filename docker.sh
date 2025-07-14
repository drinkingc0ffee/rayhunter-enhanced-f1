#!/bin/bash

# Docker wrapper script for rayhunter-enhanced
# This script calls the docker-build.sh script from the docker-build directory

# Change to the docker-build directory and run the docker-build.sh script
cd "$(dirname "$0")/docker-build"

# Pass all arguments to the docker-build.sh script
exec ./docker-build.sh "$@" 