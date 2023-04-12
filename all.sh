#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
fi

if [[ -z ${INPUT_TRUNK_TOKEN} ]]; then
  "${TRUNK_PATH}" check \
    --ci \
    --all \
    --output-file .trunk/landing-state.json \
    --github-commit "${GITHUB_SHA}" \
    ${INPUT_ARGUMENTS}
elif [[ ${INPUT_CHECK_ALL_MODE} == "hold-the-line" ]]; then
  latest_raw_upload="$(mktemp)"
  # We have to tolerate failures here: the first attempt to download the latest
  # upload for a given repo/series will always fail, because none has yet been
  # uploaded. However, we also don't want to silently suppress errors if they
  # occur: the user should be able to see them without having to set INPUT_DEBUG.
  set +e
  prev_ref="$("${TRUNK_PATH}" get-latest-raw-upload \
    --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    "${latest_raw_upload}")"
  get_latest_raw_upload_exit_code=$?
  set -e
  if [[ ${get_latest_raw_upload_exit_code} == 0 ]]; then
    htl_arg="--htl-factories-path=${latest_raw_upload}"
    git fetch origin "${prev_ref}"
  else
    echo "Failed to retrieve the latest upload. This is normal if no uploads"
    echo "have been made to this series before."
    htl_arg=""
  fi
  "${TRUNK_PATH}" check \
    --all \
    --upload \
    ${htl_arg} \
    --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    ${INPUT_ARGUMENTS}
else
  "${TRUNK_PATH}" check \
    --all \
    --output-file .trunk/landing-state.json \
    --upload \
    --series "${INPUT_UPLOAD_SERIES:-${INPUT_GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    ${INPUT_ARGUMENTS}
fi
