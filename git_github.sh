#!/bin/bash

# Run git with one-shot HTTPS auth when this action checked out the target repo.
git_github() {
  if [[ -n ${INPUT_TARGET_CHECKOUT-} ]]; then
    local token basic status xtrace_was_on=0
    # Avoid leaking the token via set -x / INPUT_DEBUG.
    case "$-" in
    *x*)
      xtrace_was_on=1
      set +x
      ;;
    *) ;;
    esac
    token="${INPUT_GITHUB_TOKEN:-${GITHUB_TOKEN-}}"
    if [[ -z ${token} ]]; then
      if [[ ${xtrace_was_on} -eq 1 ]]; then
        set -x
      fi
      echo "::error::Missing GitHub token for git against target checkout"
      exit 1
    fi
    # trunk-ignore(shellcheck/SC2312): pipeline output is captured; a failure yields an empty header and git fails loudly
    basic="$(printf 'x-access-token:%s' "${token}" | base64 | tr -d '\n\r')"
    set +e
    git -c "http.https://github.com/.extraheader=AUTHORIZATION: basic ${basic}" "$@"
    status=$?
    set -e
    if [[ ${xtrace_was_on} -eq 1 ]]; then
      set -x
    fi
    return "${status}"
  else
    git "$@"
  fi
}

fetch() {
  git_github -c protocol.version=2 fetch -q \
    --no-tags \
    --no-recurse-submodules \
    "$@"
}
