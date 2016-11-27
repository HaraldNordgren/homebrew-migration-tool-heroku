# Homebrew-versions

This repository holds migrated instances of the formulae living in the official [homebrew-versions](https://github.com/Homebrew/homebrew-versions) repository, used for installing software packages on OS X.

It is installed as Homebrew tap, see the core documentation for installing `brew` itself and handling taps.

## Installation

    brew tap HaraldNordgren/versions
    brew update

## Example usage

    brew install ansible@19
    brew install ansible@20

    brew switch ansible 19

## Homebrew Migration Tool

Migrations are performed using the [Homebrew Migration Tool](https://github.com/HaraldNordgren/homebrew-migration-tool-heroku), which is deployed as an automatic process on Heroku. It polls homebrew-versions for changes, performs the migrations when need and pushes all new migrations to this tap.

## The ideas behind

This repository intends to addresses the problem in homebrew-versions where conflicting packages live as unrelated units and need to be manualy linked and unlinked in the operating system when switching versions, like when going from `ansible19` to `ansible20`.

Here, each formula has the class name of its core version, meaning that all versions of the same package are installed into the same Cellar. This allows multiple versions to be used in parallell, and for `brew switch` to be used to dynamically go between them.

*Versions the way homebrew-versions should work.*

