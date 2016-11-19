#!/bin/bash

git remote add homebrew-versions-origin https://github.com/Homebrew/homebrew-versions
git fetch homebrew-versions-origin
git branch homebrew-versions -u homebrew-versions-origin/master

