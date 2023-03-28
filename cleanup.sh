#!/bin/bash

set -euo pipefail

echo "Cleaning up temporary files"

if [[ -n ${TRUNK_TMPDIR+x} ]]; then
  rm -rf "${TRUNK_TMPDIR}"
fi
