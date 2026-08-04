#!/bin/bash

# Unit test for git_github.sh's auth decision logic.
#
# git_github decides whether to inject one-shot HTTPS auth based on whether the
# checkout already persisted credentials. Rather than stand up an authenticated
# git server, we stub `git` so that:
#   - `git config --get-all http.<server>.extraheader` reports whether creds are
#     "persisted" (controlled by FAKE_PERSISTED), and
#   - every other `git` invocation is recorded so we can assert exactly which
#     arguments git_github passed.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../git_github.sh
source "${HERE}/../git_github.sh"

GIT_LOG=""

# Stub the real git binary for the duration of the test.
git() {
  if [[ $1 == "config" ]]; then
    if [[ ${FAKE_PERSISTED:-false} == "true" ]]; then
      echo "AUTHORIZATION: basic cGVyc2lzdGVk"
      return 0
    fi
    return 1
  fi
  printf '%s\n' "$*" >>"${GIT_LOG}"
  return 0
}

failures=0

assert_contains() {
  local desc=$1 needle=$2 haystack=$3
  if [[ ${haystack} == *"${needle}"* ]]; then
    echo "ok: ${desc}"
  else
    echo "FAIL: ${desc}"
    echo "  expected to contain: ${needle}"
    echo "  actual: ${haystack}"
    failures=$((failures + 1))
  fi
}

assert_absent() {
  local desc=$1 needle=$2 haystack=$3
  if [[ ${haystack} != *"${needle}"* ]]; then
    echo "ok: ${desc}"
  else
    echo "FAIL: ${desc}"
    echo "  expected NOT to contain: ${needle}"
    echo "  actual: ${haystack}"
    failures=$((failures + 1))
  fi
}

# Reset the environment git_github reads between scenarios.
reset_env() {
  unset INPUT_GITHUB_TOKEN GITHUB_TOKEN GITHUB_SERVER_URL FAKE_PERSISTED
  GIT_LOG=$(mktemp)
}

# 1. No persisted credentials (e.g. persist-credentials: false) + a token ->
#    inject one-shot auth for github.com and never leak the raw token.
reset_env
export FAKE_PERSISTED=false
export INPUT_GITHUB_TOKEN=super-secret-token
fetch origin main
log=$(cat "${GIT_LOG}")
assert_contains "injects auth header when credentials are not persisted" \
  "http.https://github.com/.extraheader=AUTHORIZATION: basic " "${log}"
assert_contains "still performs the requested fetch" "fetch -q" "${log}"
assert_absent "raw token is not leaked in git args" "super-secret-token" "${log}"

# 2. Persisted credentials present -> use git as-is, do not add a second header.
reset_env
export FAKE_PERSISTED=true
export INPUT_GITHUB_TOKEN=super-secret-token
fetch origin main
log=$(cat "${GIT_LOG}")
assert_absent "does not inject a second auth header when creds are persisted" \
  "extraheader" "${log}"
assert_contains "still performs the requested fetch" "fetch -q" "${log}"

# 3. No token available (e.g. public repo, no persisted creds) -> plain git.
reset_env
export FAKE_PERSISTED=false
fetch origin main
log=$(cat "${GIT_LOG}")
assert_absent "does not inject auth without a token" "extraheader" "${log}"
assert_contains "unauthenticated fetch still runs" "fetch -q" "${log}"

# 4. GitHub Enterprise Server: derive the header key from GITHUB_SERVER_URL.
reset_env
export FAKE_PERSISTED=false
export INPUT_GITHUB_TOKEN=super-secret-token
export GITHUB_SERVER_URL=https://ghe.example.com
fetch origin main
log=$(cat "${GIT_LOG}")
assert_contains "uses GITHUB_SERVER_URL for the extraheader key (GHES)" \
  "http.https://ghe.example.com/.extraheader=AUTHORIZATION: basic " "${log}"

# 5. GITHUB_TOKEN is used as a fallback when INPUT_GITHUB_TOKEN is unset.
reset_env
export FAKE_PERSISTED=false
export GITHUB_TOKEN=fallback-token
fetch origin main
log=$(cat "${GIT_LOG}")
assert_contains "falls back to GITHUB_TOKEN for auth" \
  "http.https://github.com/.extraheader=AUTHORIZATION: basic " "${log}"
assert_absent "raw fallback token is not leaked in git args" "fallback-token" "${log}"

if [[ ${failures} -gt 0 ]]; then
  echo "${failures} assertion(s) failed"
  exit 1
fi

echo "All git_github assertions passed"
