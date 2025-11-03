#!/bin/bash

mkdir -p .github
rsync -a --checksum ./ci-mvn/.github/ ./.github