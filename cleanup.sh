#!/bin/bash

set -euo pipefail

if [[ -n ${TRUNK_TMPDIR+x} ]] && [[ -z ${TEST_GITHUB_EVENT_PATH} ]]; then
  rm -rf "${TRUNK_TMPDIR}"
fi
