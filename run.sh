#!/bin/bash

set -e

nc -k -l $PORT &

mkdir -p .ssh
echo "$GITHUB_PRIVATE_SSH_KEY" > .ssh/id_rsa
chmod 600 .ssh/id_rsa
ssh-keyscan github.com >> .ssh/known_hosts

rm -rf homebrew-versions
git clone git@github.com:HaraldNordgren/homebrew-versions.git
cd homebrew-versions

git remote add homebrew-versions-origin https://github.com/Homebrew/homebrew-versions
git fetch homebrew-versions-origin
git checkout -b homebrew-versions homebrew-versions-origin/master

git config user.email "haraldnordgren+homebrew-version-migration-bot@gmail.com"
git config user.name "homebrew-version-migration-bot"
git config push.default simple

cd -
echo

./migrate.sh homebrew-versions

