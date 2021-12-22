#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

fetch() {
  git -c protocol.version=2 fetch -q \
    --no-tags \
    --prune \
    --no-recurse-submodules \
    "$@"
}

fetch origin "${GITHUB_EVENT_BEFORE}"

"${TRUNK_PATH}" check \
  --ci \
  --upstream "${GITHUB_EVENT_BEFORE}" \
  --github-commit "${GITHUB_EVENT_AFTER}" \
  --github-label "${INPUTS_LABEL}" \
  --github-annotate \
  ${INPUTS_ARGUMENTS}
