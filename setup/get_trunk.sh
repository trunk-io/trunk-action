#!/bin/bash

# Download trunk into the directory given as $1, as $1/trunk.
#
# On linux (x64, arm64) and macOS (arm64, x64) this installs the trunk CLI at the version pinned in
# cli-pins.sh, and checks its sha256 before it is extracted. The CLI runs `trunk check`, `trunk fmt`
# and the other legacy commands through the legacy launcher, so `cli.version` in .trunk/trunk.yaml
# still selects the version that runs. Other platforms (Windows) get the legacy launcher.
#
# Inputs (environment):
#   INPUT_CLI_VERSION  CLI version to install (default: the pinned version)
#   INPUT_CLI_CHANNEL  release channel (default: the pinned channel)
#   INPUT_LAUNCHER     "new" (default) or "legacy" (always use the legacy launcher)

set -euo pipefail

if [[ ${INPUT_DEBUG:-false} == "true" ]]; then
  set -x
fi

dest_dir="$1"
mkdir -p "${dest_dir}"

# shellcheck source=setup/cli-pins.sh
source "$(dirname "${BASH_SOURCE[0]}")/cli-pins.sh"

launcher="${INPUT_LAUNCHER:-new}"
version="${INPUT_CLI_VERSION:-${TRUNK_CLI_PIN_VERSION}}"
channel="${INPUT_CLI_CHANNEL:-${TRUNK_CLI_PIN_CHANNEL}}"

if [[ ${launcher} != "new" && ${launcher} != "legacy" ]]; then
  echo "::error::Unknown launcher '${launcher}' (expected 'new' or 'legacy')"
  exit 1
fi
if [[ ! ${version} =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]]; then
  echo "::error::Invalid cli-version '${version}'"
  exit 1
fi
if [[ ! ${channel} =~ ^[a-z0-9-]+$ ]]; then
  echo "::error::Invalid cli-channel '${channel}'"
  exit 1
fi

fetch() {
  if ! curl -fsSL "$1" -o "$2"; then
    echo "::error::Failed to download $1"
    exit 1
  fi
}

get_legacy_launcher() {
  fetch https://trunk.io/releases/trunk "${dest_dir}/trunk"
  chmod u+x "${dest_dir}/trunk"
}

# Select the platform before any download. The CLI has no Windows build.
platform=""
kernel="$(uname -s)"
machine="$(uname -m)"
case "${machine}" in
aarch64 | arm64) arch="arm64" ;;
x86_64 | amd64) arch="x64" ;;
*) arch="" ;;
esac
case "${kernel}" in
Linux) [[ -n ${arch} ]] && platform="linux-${arch}" ;;
Darwin)
  # A shell under Rosetta 2 on Apple silicon reports x86_64; the native arm64 build is the right one.
  translated="$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)"
  if [[ ${arch} == "x64" && ${translated} == "1" ]]; then
    arch="arm64"
  fi
  [[ -n ${arch} ]] && platform="darwin-${arch}"
  ;;
*) ;;
esac

if [[ ${launcher} == "legacy" ]]; then
  echo "::notice::Using the legacy trunk launcher (launcher: legacy)"
  get_legacy_launcher
  exit 0
fi
if [[ -z ${platform} ]]; then
  echo "::notice::The trunk CLI has no build for ${kernel} ${machine}; using the legacy trunk launcher"
  get_legacy_launcher
  exit 0
fi

if command -v sha256sum >/dev/null 2>&1; then
  sha_tool=(sha256sum)
elif command -v shasum >/dev/null 2>&1; then
  sha_tool=(shasum -a 256)
else
  echo "::error::sha256sum or shasum is necessary to verify the trunk CLI download"
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

release_url="https://trunk.io/releases/trunk-cli/${channel}/${version}"
if [[ ${version} == "${TRUNK_CLI_PIN_VERSION}" && ${channel} == "${TRUNK_CLI_PIN_CHANNEL}" ]]; then
  sha_var="TRUNK_CLI_PIN_SHA256_${platform//-/_}"
  expected="${!sha_var-}"
else
  # A version that is not pinned in this action: use the sha256 from its release manifest.
  fetch "${release_url}/manifest.json" "${workdir}/manifest.json"
  expected="$(jq -r --arg p "${platform}" '.platforms[$p].sha256 // empty' "${workdir}/manifest.json")"
fi
if [[ -z ${expected} ]]; then
  echo "::error::trunk CLI ${version} (${channel}) has no ${platform} build"
  exit 1
fi

tarball="trunk-${version}-${platform}.tar.gz"
fetch "${release_url}/${tarball}" "${workdir}/${tarball}"
actual="$("${sha_tool[@]}" "${workdir}/${tarball}" | cut -d' ' -f1)"
if [[ ${actual} != "${expected}" ]]; then
  echo "::error::sha256 mismatch for ${tarball}: expected ${expected}, got ${actual}"
  exit 1
fi

(cd "${workdir}" && tar -xzf "${tarball}" trunk)
chmod u+x "${workdir}/trunk"
reported="$(TRUNK_NO_AUTO_UPDATE=1 "${workdir}/trunk" --version 2>/dev/null || true)"
if [[ ${reported} != "trunk ${version}" ]]; then
  echo "::error::The downloaded trunk CLI failed its health check (reported: ${reported:-nothing})"
  exit 1
fi
mv -f "${workdir}/trunk" "${dest_dir}/trunk"

# The same markers as install.trunk.io --version: a pin stops self-update, and a non-prod channel is
# recorded next to the binary.
printf '%s' "${version}" >"${dest_dir}/trunk.pinned"
if [[ ${channel} != "prod" ]]; then
  printf '%s' "${channel}" >"${dest_dir}/trunk.channel"
fi
if [[ -n ${GITHUB_ENV-} ]]; then
  echo "TRUNK_NO_AUTO_UPDATE=1" >>"${GITHUB_ENV}"
fi
echo "::notice::Using trunk CLI ${version} (${channel}, ${platform})"
