#!/bin/bash

set -euo pipefail

"${TRUNK_PATH}" check \
  --ci \
  --all \
  --upstream "${GITHUB_SHA}" \
  --github-commit "${GITHUB_SHA}" \
  --github-label "${INPUTS_LABEL}" \
  --github-annotate
