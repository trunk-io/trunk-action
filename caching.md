# Caching Semantics

## Invoked from a GitHub workflow

We cache the contents of `~/.cache/trunk/` if `inputs.cache === true`.

Note that the GitHub Actions cache only caches results on a per-branch/per-PR basis, so the first
time `Trunk Check` runs on a given branch, it will be uncached. Subsequent runs will read from
cache.

## Invoked inside the `.trunk` repo

We only cache the contents of `~/.cache/trunk/tools/ruby/` (Ruby is the only tool install that is
painfully slow, since it has to be built from scratch on every single install).

Although we _could_ cache all of `~/.cache/trunk/`, doing so would yield no benefit:

- GitHub starts evicting cache entries once the size of all GitHub Actions cache entries for a repo
  exceeds 10GiB ([documentation][gha-cache-limits]).

- We expect the cache size to be dominated by `~/.cache/trunk/tools/`, which for all tools in a repo
  usually reaches into multiple GiB, even compressed.

- Since Trunk Check will run for all repos in a given GitHub org in workflows in `your-org/.trunk`,
  all such repos end up sharing the `.trunk` GitHub Actions cache, eventually the sizes of each
  repo's cache entry will cause them to stomp on each other.

Experimentally, installing all tools from scratch (except Ruby) only takes ~1 min, so we don't
believe there will be any noticeable benefit to caching the contents of the tools cache.

We don't expect caching linter results to be a significant improvement either.

[gha-cache-limits]:
  https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows#usage-limits-and-eviction-policy
