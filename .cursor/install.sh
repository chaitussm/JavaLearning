#!/usr/bin/env bash
set -euo pipefail

if ! command -v mvn >/dev/null; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y maven
fi

if [ -f demo/pom.xml ]; then
  mvn -B -f demo/pom.xml compile -q
fi
