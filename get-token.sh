#!/bin/bash
# Get GitHub runner registration token
# Requires GitHub Personal Access Token with 'repo' and 'workflow' scopes

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: Set GITHUB_TOKEN environment variable"
    echo "Generate at: https://github.com/settings/tokens/new"
    echo "Required scopes: repo, workflow"
    exit 1
fi

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/camerony/Affine-custom/actions/runners/registration-token \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4
