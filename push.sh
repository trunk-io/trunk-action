#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
fi

if [[ ${GITHUB_EVENT_BEFORE} == "0000000000000000000000000000000000000000" ]]; then
  # Github will send us all 0s for the before hash in a few circumstances, such as the first commit to a repo
  # or pushing a tag. In these instances we will check the whole repo.
  "${TRUNK_PATH}" check \
    --ci \
    --all \
    --github-commit "${GITHUB_EVENT_AFTER}" \
    ${INPUT_ARGUMENTS}
  exit
fi

"${TRUNK_PATH}" check \
  --ci \
  --upstream "${upstream}" \
  --github-commit "${GITHUB_EVENT_AFTER}" \
  ${INPUT_ARGUMENTS}
