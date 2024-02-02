#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

"${TRUNK_PATH}" install \
  --ci \
  ${INPUT_ARGUMENTS}
