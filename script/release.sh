#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT=${ENVIRONMENT:-prod}

git fetch origin --tags

# Find the next available tag
i=1
tag="release/$ENVIRONMENT/$(date -u "+%Y-%m-%d")/$i"
until [[ -z $(git tag -l "$tag") ]] ; do
    i=$((i + 1))
    tag="release/$ENVIRONMENT/$(date -u "+%Y-%m-%d")/$i"
done

git tag "$tag"
git push origin "$tag"

if repo=$(git remote -v | grep push | awk '{print $2}' | cut -d ':' -f 2) ; then
	echo "Create a release with this url:"
	echo "https://github.com/${repo}/releases/new?tag=${tag}"
fi
