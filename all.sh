#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
fi

fetch() {
  git -c protocol.version=2 fetch -q \
    --no-tags \
    --no-recurse-submodules \
    "$@"
}

MINIMUM_UPLOAD_ID_VERSION=1.12.3

if [[ -z ${INPUT_TRUNK_TOKEN} ]]; then
  "${TRUNK_PATH}" check \
    --ci \
    --all \
    --github-commit "${GITHUB_SHA}" \
    ${INPUT_ARGUMENTS}
elif [[ ${INPUT_CHECK_ALL_MODE} == "hold-the-line" ]]; then
  latest_raw_upload="$(mktemp)"
  prev_ref="$("${TRUNK_PATH}" check get-latest-raw-output \
    --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
    "${latest_raw_upload}")"
  if [[ ${prev_ref} =~ .*"new series".* ]]; then
    echo "${prev_ref}"
    htl_arg=""
  else
    htl_arg="--htl-factories-path=${latest_raw_upload}"
    fetch origin "${prev_ref}"
  fi
  if [[ -n ${INPUT_UPLOAD_ID-} ]]; then # if upload ID unset, skip it instead of erroring
    upload_id_arg="--upload-id ${INPUT_UPLOAD_ID}"
    trunk_version="$(${TRUNK_PATH} version)"
    # trunk-ignore-begin(shellcheck/SC2312): the == will fail if anything inside the $() fails
    if sort_result=$(printf "%s\n%s\n" "${MINIMUM_UPLOAD_ID_VERSION}" "${trunk_version}" | sort --version-sort); then
      if [[ $(echo "${sort_result}" | head -n 1) == "${trunk_version}" ]]; then
        echo "::error::Please update your CLI to ${MINIMUM_UPLOAD_ID_VERSION} or higher (current version ${trunk_version})."
        exit 1
      fi
    else
      echo "::warning::sort --version-sort failed - continuing without checking CLI version"
    fi
    # trunk-ignore-end(shellcheck/SC2312)
  else
    upload_id_arg=""
  fi
  "${TRUNK_PATH}" check \
    --all \
    --upload \
    ${htl_arg} \
    ${upload_id_arg} \
    --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
    --debug \
    ${INPUT_ARGUMENTS}
else
  "${TRUNK_PATH}" check \
    --all \
    --upload \
    --series "${INPUT_UPLOAD_SERIES:-${INPUT_GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    --debug \
    ${INPUT_ARGUMENTS}
fi
