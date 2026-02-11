#!/bin/sh
set -euf
PROJECTDIR=$(dirname "$0")
PROJECTDIR=$(cd "$PROJECTDIR/../.." && pwd)

# parse options
limit=30
repository=
usage() {
  echo "Usage: import-latest-gh-releases.sh [-l limit] -r repository package ..." >&2
  echo "Import the latest GitHub release for each \`package\` with tag \`<version>+<package>\`" >&2
  echo "Example: import-latest-gh-releases.sh -r diskuv/dk CommonsBase_Std CommonsBase_Build" >&2
  exit 1
}
while getopts "l:r:" opt; do
  case $opt in
    l) limit="$OPTARG" ;;
    r) repository="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
if [ $# -lt 1 ]; then
  usage
fi
if [ -z "$repository" ]; then
  echo "Error: repository is required" >&2
  usage
fi

# loop through packages and import the latest release for each
for package in "$@"; do
  tag="$("$PROJECTDIR"/.github/scripts/get-latest-gh-release.sh -l "$limit" -r "$repository" "$package")"
  if [ -z "$tag" ]; then
    echo "Error: no release found for package $package in repository $repository. You might need to increase the limit $limit with -l <new_limit>" >&2
    exit 1
  fi

  printf "Importing release %s for package %s from repository %s:\n" "$tag" "$package" "$repository"
  printf "./dk0 --trial import-github-l2 --repo %s --tag %s --outdir %s/etc/dk/i/\n" "$repository" "$tag" "$PROJECTDIR"
  ./dk0 --trial import-github-l2 --repo "$repository" --tag "$tag" --outdir "$PROJECTDIR"/etc/dk/i/
done
