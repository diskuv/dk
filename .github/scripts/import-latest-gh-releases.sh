#!/bin/sh
set -euf
PROJECTDIR=$(dirname "$0")
PROJECTDIR=$(cd "$PROJECTDIR/../.." && pwd)

# parse options
limit=30
repository=
capturefile=
capturemarkdown=false
usage() {
  echo "Usage: import-latest-gh-releases.sh [-l limit] [-c capturefile] [-m] -r repository package ..." >&2
  echo "Import the latest GitHub release for each \`package\` with tag \`<version>+<package>\`." >&2
  echo "-c: A capturefile will be appended with the import command for each package" >&2
  echo "    so that the commands can be re-run manually and committed." >&2
  echo "-m: Use Markdown when writing the capturefile. Useful in GitHub Actions" >&2
  echo "    with '-c \$GITHUB_STEP_SUMMARY' for easy copy-and-paste in the job." >&2
  echo "-l: The number of GitHub releases when searching for the package. Default is 30." >&2
  echo "Example: import-latest-gh-releases.sh -r diskuv/dk CommonsBase_Std CommonsBase_Build" >&2
  exit 1
}
while getopts "l:r:c:m" opt; do
  case $opt in
    l) limit="$OPTARG" ;;
    r) repository="$OPTARG" ;;
    c) capturefile="$OPTARG" ;;
    m) capturemarkdown=true ;;
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

if [ "$capturemarkdown" = true ]; then
    printf "### Imported packages\n\n" >> "$capturefile"
    printf '```\n' >> "$capturefile"
fi

# loop through packages and import the latest release for each
for package in "$@"; do
  tag="$("$PROJECTDIR"/.github/scripts/get-latest-gh-release.sh -l "$limit" -r "$repository" "$package")"
  if [ -z "$tag" ]; then
    echo "Error: no release found for package $package in repository $repository. You might need to increase the limit $limit with -l <new_limit>" >&2
    exit 1
  fi

  printf -- "------------------------------------------------\n" >&2
  printf "Importing release %s for package %s from repository %s:\n" "$tag" "$package" "$repository"
  printf "./dk0 --trial import-github-l2 --repo %s --tag %s --outdir %s/etc/dk/i/\n\n" "$repository" "$tag" "$PROJECTDIR"
  if [ -n "$capturefile" ]; then
    printf "./dk0 --trial import-github-l2 --repo %s --tag %s --outdir etc/dk/i/\n" "$repository" "$tag" >> "$capturefile"
  fi
  ./dk0 --trial import-github-l2 --repo "$repository" --tag "$tag" --outdir "$PROJECTDIR"/etc/dk/i/
  printf -- "------------------------------------------------\n\n" >&2
done

if [ "$capturemarkdown" = true ]; then
    printf '```\n' >> "$capturefile"
fi

# The presence of values.unattested.json file left by `import-github-l2` is
# confusing in a CI job that does the attestation later.
rm -f "$PROJECTDIR"/etc/dk/i/values.unattested.json
