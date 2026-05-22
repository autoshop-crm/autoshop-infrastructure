#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

mode="${1:-clone-if-missing}"

require_command git

for repo in $(manifest_repos); do
  target="$(repo_target_dir "$repo")"
  url="$(repo_clone_url "$repo")"

  if [[ -d "$target/.git" ]]; then
    case "$mode" in
      clone-if-missing)
        log "$repo already exists at $target; skipping"
        ;;
      pull-if-exists)
        if [[ -n "$(git -C "$target" status --porcelain)" ]]; then
          die "$repo has uncommitted changes at $target"
        fi
        log "Pulling latest changes for $repo"
        git -C "$target" pull --ff-only
        ;;
      fail-if-dirty)
        if [[ -n "$(git -C "$target" status --porcelain)" ]]; then
          die "$repo has uncommitted changes at $target"
        fi
        log "$repo already exists and is clean"
        ;;
      *)
        die "Unsupported clone mode: $mode"
        ;;
    esac
    continue
  fi

  if [[ -e "$target" ]]; then
    die "Target path exists but is not a git repo: $target"
  fi

  if ! git ls-remote "$url" >/dev/null 2>&1; then
    die "Cannot access repository $repo via $url. Check Git credentials or AUTOSHOP_REPO_BASE_URL"
  fi

  log "Cloning $repo from $url"
  git clone "$url" "$target"
done

log "Repository bootstrap finished"
