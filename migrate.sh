#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Supply repo dir to migrate"
    exit 1
fi

base_dir="$(dirname $BASH_SOURCE)"
migrate_versions="$base_dir"/migrate_versions.rb

cd "$1"

git checkout homebrew-versions
git pull

timestamp=$(date +%s)
staging_branch=homebrew-versions-$timestamp

echo
echo "RUNNING MIGRATIONS"
git checkout -b $staging_branch
ruby "$migrate_versions"
git add .
git commit -m "Auto-migration $timestamp"

echo "MERGING IN CHANGES"
git checkout master
#if ! git cherry-pick staging_branch; then
if ! git merge $staging_branch; then
    git add .
    git commit --no-edit
    #git cherry-pick --continue
fi

