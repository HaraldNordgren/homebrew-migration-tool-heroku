#!/bin/bash

set -e

migrate_versions=migrate_versions.rb

if [ -z "$1" ]; then
    echo "Supply repo dir to migrate"
    exit 1
fi

cd "$1"

echo "PULLING LATEST COMMITS FROM HOMEBREW-VERSIONS"
git pull

latest_homebrew_commit=$(git rev-parse HEAD)
if git log master --pretty=%B | grep -q $latest_homebrew_commit ; then
    echo "NOTHING NEW TO MIGRATE"
    exit 0
fi

staging_branch=homebrew-versions-$latest_homebrew_commit

echo
git checkout -b $staging_branch

ruby "$migrate_versions"
git add . -A
git commit -m "Migrated 'Homebrew/homebrew-versions' up to $latest_homebrew_commit" -q

echo "MERGING BRANCHES"
git checkout master -q
git merge $staging_branch -X theirs --no-edit -q

echo
echo "PUSHING TO REMOTE"
git push
git branch -d $staging_branch

git checkout homebrew-versions -q

echo "MIGRATION COMPLETED"
exit 0

