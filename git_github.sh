#!/bin/bash

# Authenticate git against the GitHub server for trunk's internal fetches and
# autofix pushes.
#
# When the checkout step persisted credentials (the default), git already has
# auth in .git/config and we run it unchanged. When credentials were not
# persisted -- e.g. the caller set `persist-credentials: false`, or this action
# did its own target checkout that way -- we add one-shot HTTPS auth for this
# single invocation using the action's token, without writing it to the git
# config for later steps. With no token available we fall back to plain git so
# unauthenticated public fetches keep working.
git_github() {
  local server token
  server="${GITHUB_SERVER_URL:-https://github.com}"
  token="${INPUT_GITHUB_TOKEN:-${GITHUB_TOKEN-}}"

  # Use git as-is when we have no token to offer, or when the checkout already
  # persisted credentials for this server (avoids sending a second, conflicting
  # Authorization header and preserves any custom persisted token).
  if [[ -z ${token} ]] || git config --get-all "http.${server}/.extraheader" >/dev/null 2>&1; then
    git "$@"
    return
  fi

  local basic status xtrace_was_on=0
  # Avoid leaking the token via set -x / INPUT_DEBUG.
  case "$-" in
  *x*)
    xtrace_was_on=1
    set +x
    ;;
  *) ;;
  esac
  # trunk-ignore(shellcheck/SC2312): pipeline output is captured; a failure yields an empty header and git fails loudly
  basic="$(printf 'x-access-token:%s' "${token}" | base64 | tr -d '\n\r')"
  set +e
  git -c "http.${server}/.extraheader=AUTHORIZATION: basic ${basic}" "$@"
  status=$?
  set -e
  if [[ ${xtrace_was_on} -eq 1 ]]; then
    set -x
  fi
  return "${status}"
}

fetch() {
  git_github -c protocol.version=2 fetch -q \
    --no-tags \
    --no-recurse-submodules \
    "$@"
}
