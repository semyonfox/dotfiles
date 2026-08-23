#!/usr/bin/env bash

set -euo pipefail

command -v gh >/dev/null || {
  echo "gh is required" >&2
  exit 2
}

command -v jq >/dev/null || {
  echo "jq is required" >&2
  exit 2
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "run this inside the pull request repository" >&2
  exit 2
}

cd "$repo_root"
local_head=$(git rev-parse HEAD)
pr_json=$(gh pr view --json number,url,isDraft,mergeable,mergeStateStatus,headRefOid,statusCheckRollup)

pr_url=$(jq -r '.url' <<<"$pr_json")
pr_head=$(jq -r '.headRefOid' <<<"$pr_json")
is_draft=$(jq -r '.isDraft' <<<"$pr_json")
mergeable=$(jq -r '.mergeable' <<<"$pr_json")
merge_state=$(jq -r '.mergeStateStatus' <<<"$pr_json")

if [[ "$pr_head" != "$local_head" ]]; then
  echo "blocked: local HEAD does not match the pull request head" >&2
  exit 1
fi

if [[ "$is_draft" == "true" ]]; then
  echo "blocked: pull request is still a draft" >&2
  exit 1
fi

if [[ "$mergeable" != "MERGEABLE" ]]; then
  echo "blocked: pull request mergeability is $mergeable" >&2
  exit 1
fi

failed_checks=$(jq -r '
  [
    .statusCheckRollup[]?
    | if .__typename == "CheckRun" then
        select((.status != "COMPLETED") or ((.conclusion // "") | IN("SUCCESS", "NEUTRAL", "SKIPPED") | not))
        | (.name // "unnamed check") + ": " + (.status // "UNKNOWN") + "/" + (.conclusion // "UNKNOWN")
      else
        select((.state // "") != "SUCCESS")
        | (.context // "unnamed status") + ": " + (.state // "UNKNOWN")
      end
  ]
  | .[]
' <<<"$pr_json")

if [[ -n "$failed_checks" ]]; then
  echo "blocked: checks are not green" >&2
  printf '%s\n' "$failed_checks" >&2
  exit 1
fi

if [[ "$merge_state" != "CLEAN" && "$merge_state" != "HAS_HOOKS" ]]; then
  echo "blocked: GitHub merge state is $merge_state" >&2
  exit 1
fi

echo "green: $pr_url at $local_head"
