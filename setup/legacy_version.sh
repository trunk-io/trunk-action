#!/bin/bash

# Print the version of the legacy trunk CLI that $1 runs (the `cli.version` in .trunk/trunk.yaml).
# This also downloads that version if it is not cached yet.
#
# For the legacy launcher, `trunk version` prints that version. For the trunk CLI, `trunk version`
# prints "trunk <x.y.z>" (its own version), and `trunk legacy version` prints the legacy version.

set -euo pipefail

trunk_path="$1"

version="$("${trunk_path}" version)"
if [[ ${version} =~ ^trunk\ [0-9] ]]; then
  "${trunk_path}" legacy version
else
  echo "${version}"
fi
