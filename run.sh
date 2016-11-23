#!/bin/bash

set -e

nc -k -l $PORT &

mkdir -p .ssh
echo "$GITHUB_PRIVATE_SSH_KEY" > .ssh/id_rsa
chmod 600 .ssh/id_rsa
ssh-keyscan github.com >> .ssh/known_hosts

base_dir="$PWD"
migrate_versions="$base_dir"/migrate_versions.rb

git clone git@github.com:HaraldNordgren/homebrew-versions.git
cd homebrew-versions

git remote add homebrew-versions-origin https://github.com/Homebrew/homebrew-versions
git fetch homebrew-versions-origin
git checkout -b homebrew-versions homebrew-versions-origin/master

git config user.email "haraldnordgren+homebrew-version-migration-bot@gmail.com"
git config user.name "homebrew-version-migration-bot"
git config push.default simple

echo
echo "PULLING LATEST COMMITS FROM HOMEBREW-VERSIONS"
git pull

latest_homebrew_commit=$(git rev-parse HEAD)
if git log master --pretty=%B | grep -q $latest_homebrew_commit ; then
    echo "NOTHING NEW TO MIGRATE"
    exit 0
fi

echo
staging_branch=homebrew-versions-$latest_homebrew_commit
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

