#!/bin/bash

set -e

base_dir="$PWD"
migrate_versions="$base_dir"/migrate_versions.rb
#README="$base_dir"/homebrew-versions-harald-README/README.md

if [ -n "$GITHUB_PRIVATE_SSH_KEY" ]; then
    nc -k -l $PORT &

    mkdir -p .ssh
    echo "$GITHUB_PRIVATE_SSH_KEY" > .ssh/id_rsa
    chmod 600 .ssh/id_rsa
    ssh-keyscan github.com >> .ssh/known_hosts
    github_adress="git@github.com:HaraldNordgren/homebrew-versions.git"
    #github_adress="git@github.com:HaraldNordgren/homebrew-versions-cherry.git"
else
    rm -rf homebrew-versions
    github_adress="https://github.com/HaraldNordgren/homebrew-versions.git"
    #github_adress="https://github.com/Homebrew/homebrew-versions.git"
    #github_adress="https://github.com/HaraldNordgren/homebrew-versions-cherry.git"
fi

echo
echo "CLONING $github_adress"
git clone $github_adress homebrew-versions
cd homebrew-versions

git remote add homebrew-versions-origin https://github.com/Homebrew/homebrew-versions
git fetch homebrew-versions-origin
git checkout -b homebrew-versions homebrew-versions-origin/master -q

git config user.email "haraldnordgren+homebrew-version-migration-bot@gmail.com"
git config user.name "homebrew-version-migration-bot"
git config push.default simple

echo
echo "PULLING LATEST COMMITS FROM HOMEBREW-VERSIONS"
git pull

unmigrated_commits=

for hash in $(git log homebrew-versions --pretty=%H); do
    #echo "Searching for $hash in migrated commit log"
    if git log master --pretty=%B | grep -q $hash; then
        break
    fi

    unmigrated_commits="$hash $unmigrated_commits"
done

if [ -z "$unmigrated_commits" ]; then
    echo "NOTHING NEW TO MIGRATE"
    exit 0
fi

for commit in $unmigrated_commits; do
    echo
    echo "MIGRATING $commit"
    staging_branch=homebrew-versions-$commit
    git checkout -b $staging_branch $commit

    git checkout master migrated_packages.json || true
    ruby "$migrate_versions"

    # Ruby processing to avoid spammy notifications on push
    homebrew_message=$(git log $commit --pretty=%B -n1 | ruby -ne 'print $_.sub(/^@/, "").gsub(/ @/, " ")')

    git commit -m "Migrating $commit: '$homebrew_message'" -q
    migration_hash=$(git rev-parse HEAD)

    echo
    echo "MERGING BRANCHES"
    git checkout master -q

    git checkout $migration_hash Formula Aliases
    git checkout $migration_hash LICENSE || true
    git checkout $migration_hash migrated_packages.json

    git status -u

    if [ -n "$(git status --porcelain)" ]; then
        git commit -m "Migrated $commit: '$homebrew_message'" -q
    else
        git commit -m "[skip ci] Migrated $commit: '$homebrew_message'" --allow-empty -q
    fi

    echo
    echo "PUSHING TO REMOTE"
    git push

    git branch -D $staging_branch

    echo "####################################################"
done

echo "MIGRATION COMPLETED"
exit 0

