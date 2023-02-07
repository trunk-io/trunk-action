#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

if [[ -z ${INPUT_TRUNK_TOKEN} ]]; then
  "${TRUNK_PATH}" check \
    --ci \
    --all \
    --output-file .trunk/landing_state.json \
    --github-commit "${GITHUB_SHA}" \
    ${INPUT_ARGUMENTS}
else
  "${TRUNK_PATH}" check \
    --all \
    --output-file .trunk/landing_state.json \
    --upload \
    --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    ${INPUT_ARGUMENTS}
fi
