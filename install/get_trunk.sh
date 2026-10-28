#!/bin/bash

set -euo pipefail

if [[ ${INPUT_DEBUG:-false} == "true" ]]; then
  set -x
fi

tmpdir="$(mktemp -d)"
echo "TRUNK_TMPDIR=${tmpdir}" >>"${GITHUB_ENV}"

"$(dirname "${BASH_SOURCE[0]}")/../setup/get_trunk.sh" "${tmpdir}"
trunk_path="${tmpdir}/trunk"

echo "TRUNK_PATH=${trunk_path}" >>"${GITHUB_ENV}"
echo "${tmpdir}" >>"${GITHUB_PATH}"

# Ensure that trunk CLI is downloaded before subsequent steps (swallow output of version command)
("$(dirname "${BASH_SOURCE[0]}")/../setup/legacy_version.sh" "${trunk_path}" >/dev/null 2>&1) || echo "::warning::${trunk_path} does not exist!"
