# crs-dev-tool

Shell script for automating some common CRS development functions.

Currently tested only on macOS, will accept patches to improve this.

Necessary dependencies: awk, curl, Docker, git.

## Installation

Download the script anywhere you like to store random programs, like `~/bin`:

```sh
curl -o ~/bin/crs https://raw.githubusercontent.com/lifeforms/crs-dev-tool/master/crs.sh
chmod a+x ~/bin/crs
```

## Configuration

Run `crs` once to create an example configuration file `~/.crs`.

Edit the file `~/.crs` in your favorite editor, defining your CRS code directory and the URL of your CRS Github fork. If you haven't made a fork yet, the file will give you instructions on how to do this.

## Getting and refreshing CRS code

- `crs branch` will show you all currently available dev branches, like `v3.1/dev`
- `crs clean v3.1/dev` will initialize your code directory, check out your fork with the `v3.1/dev` CRS branch, and add the upstream remote. Warning: this will destroy any local content in your code directory!
- `crs merge` integrates upstream changes into your fork and code directory. Do this regularly, so you're not too far behind.

## Reviewing issues and PRs

- `crs issue` will open a browser at the GitHub CRS issues page.
- `crs issue 1234` will open a browser with issue or PR #1234 open.
- `crs review user:branch` will check out that user's CRS fork and branch, so you can compare and test.

## Running tests

- `crs test` will run the full test suite on your local CRS directory.
- `crs serve` will run a web server on the CRS at http://localhost/
- `crs shell` executes bash inside a running container that's busy testing/serving. It might be used for debugging.

## Miscellaneous functions

- `crs update` will download the latest version of this shell script from this repository and overwrite itself.
- `crs help` will display helpful help.
