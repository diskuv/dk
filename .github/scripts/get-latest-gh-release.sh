#!/bin/sh
set -euf

# parse options
limit=30
repository=
usage() {
  echo "Usage: get-latest-gh-release.sh [-l limit] [-r repository] package" >&2
  echo "Get the GitHub release for \`package\` with the latest tag \`<version>+<package>\`" >&2
  echo "-l: The number of GitHub releases when searching for the package. Default is 30." >&2
  echo "Example: get-latest-gh-release.sh -r diskuv/dk CommonsBase_Std" >&2
  echo "Sample output: 2.5.202602060017+CommonsBase-Std" >&2
  echo "There will be no output if no matching release is found." >&2
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
if [ $# -ne 1 ]; then
  usage
fi
package="$1"

# validate to mitigate injection risks in `gh` command
# + use `tr` to avoid regex portability in `grep`

# validate limit to be a positive integer
if printf "%s" "$limit" | tr -d '0-9' | grep -q .; then
  echo "Error: limit must be a positive integer: $limit" >&2
  exit 1
fi

# validate repository to be in the form of owner/repo
if [ -n "$repository" ] && printf "%s" "$repository" | tr -d 'A-Za-z0-9_/' | grep -q .; then
  echo "Error: repository must be in the form of owner/repo with alphanumeric characters, underscores, and slashes: $repository" >&2
  exit 1
fi

# validate package to be [A-Za-z0-9_]+
if printf "%s" "$package" | tr -d 'A-Za-z0-9_' | grep -q .; then
  echo "Error: package name must be alphanumeric with optional underscores: $package" >&2
  exit 1
fi

# replace underscore with one dash ("-") in package to make valid semver build metadata
package=$(printf "%s" "$package" | tr '_' '-')

exec_gh() {
  exec gh release list \
    --limit "$limit" \
    --exclude-drafts --exclude-pre-releases \
    --json tagName \
    --jq "[ .[] | select(.tagName | endswith(\"+$package\")) ] | first | .tagName" \
    "$@"
}

if [ -n "$repository" ]; then
  exec_gh -R "$repository"
else
  exec_gh
fi
