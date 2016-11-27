# Homebrew-versions

This tap holds migrated instances of the formulae living in the official [homebrew-versions](https://github.com/Homebrew/homebrew-versions) repository.

## Installing formulae

    brew tap HaraldNordgren/versions
    brew update

## Example usage

    brew install ansible@19
    brew install ansible@20


    brew switch ansible 19

## Internals

Migrations are performed using the [Homebrew Migration Tool](https://github.com/HaraldNordgren/homebrew-migration-tool-heroku) which is deployed as an automatic process on Heroku that polls homebrew-versions hourly for changes, performs the migrations, and pushes new migrations to this repository.

This tap intends to addresses a problem in homebrew-versions where conflicting packages live as totally unrelated units, and need to be manualy linked and unlinked in the operating system when switching versions. Like when going from ansible19 to ansible20.

Here, each formula has a the class name of its core version, meaning that all versions of the same package are installed into the same Cellar. This allows multiple versions to be used in parallell, and for `brew switch` to be used to dynamically go between them.

Versions the way homebrew-versions should work.

