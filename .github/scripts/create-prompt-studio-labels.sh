#!/bin/sh
# Create or update the GitHub labels used by the dk Prompt Studio issue
# templates. Idempotent: re-running updates color and description in place.
#
# Requires the GitHub CLI (`gh`) authenticated against github.com/diskuv/dk.
# Usage: sh create-prompt-studio-labels.sh [OWNER/REPO]
# OWNER/REPO defaults to diskuv/dk.
set -eu

REPO="${1:-diskuv/dk}"

create() {
  name="$1"
  color="$2"
  description="$3"
  gh label create "$name" --repo "$REPO" --color "$color" \
    --description "$description" --force
}

create "from-prompt-studio" "5319e7" "Filed from a dk Prompt Studio mini-plan"
create "new-package"        "0e8a16" "Request to adopt a tool or library as a dk package"
create "miniplan-failure"   "d73a4a" "A mini-plan stalled or failed while building"
create "miniplan-success"   "0e8a16" "A mini-plan produced working software"
create "implemented"        "1d76db" "The requested dk package is created, tested, and available"

echo "Labels created or updated on $REPO."
