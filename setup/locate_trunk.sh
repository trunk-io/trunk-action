#!/bin/bash

set -euo pipefail

if [[ ${INPUT_DEBUG:-false} == "true" ]]; then
  set -x
fi

tmpdir="$(mktemp -d)"
echo "TRUNK_TMPDIR=${tmpdir}" >>"${GITHUB_ENV}"

trunk_path="${INPUT_TRUNK_PATH}"
if [[ -z ${trunk_path} ]]; then
  if [[ -f .trunk/bin/trunk && -x .trunk/bin/trunk ]]; then
    trunk_path=.trunk/bin/trunk
  elif [[ -f tools/trunk && -x tools/trunk ]]; then
    trunk_path=tools/trunk
  elif [[ -f trunk && -x trunk ]]; then
    trunk_path=./trunk
  else
    "$(dirname "${BASH_SOURCE[0]}")/get_trunk.sh" "${tmpdir}"
    trunk_path="${tmpdir}/trunk"
  fi
fi
echo "TRUNK_PATH=${trunk_path}" >>"${GITHUB_ENV}"
# Ensure that trunk CLI is downloaded before subsequent steps
"$(dirname "${BASH_SOURCE[0]}")/legacy_version.sh" "${trunk_path}" || echo "::warning::${trunk_path} does not exist!"
