#!/bin/bash

set -euo pipefail

# Usage: run_with_timeout.sh <script-name>
script_name="${1:?script name required}"

if [[ ${INPUT_TIMEOUT_SECONDS:-0} != "0" ]]; then
  timeout "${INPUT_TIMEOUT_SECONDS}" "${GITHUB_ACTION_PATH}/${script_name}"
else
  "${GITHUB_ACTION_PATH}/${script_name}"
fi
