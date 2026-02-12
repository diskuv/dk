#!/bin/sh
set -euf
PROJECTDIR=$(dirname "$0")
PROJECTDIR=$(cd "$PROJECTDIR/../.." && pwd)

# parse options
tag=
repository=
capturefile=
capturemarkdown=false
usage() {
  echo "Usage: describe-import-gh-release.sh [-c capturefile] [-m] -t tag -r repository" >&2
  echo "-c: A capturefile will be appended with the import command for each package" >&2
  echo "    so that the commands can be re-run manually and committed." >&2
  echo "-m: Use Markdown when writing the capturefile. Useful in GitHub Actions" >&2
  echo "    with '-c \$GITHUB_STEP_SUMMARY' for easy copy-and-paste in the job." >&2
  echo "-t: The tag of the GitHub release to import." >&2
  echo "-r: The GitHub repository in the format 'owner/repo'." >&2
  echo "Example: describe-import-gh-release.sh -t 2.5.1 -r diskuv/dk CommonsBase_Std CommonsBase_Build" >&2
  exit 1
}
while getopts "t:r:c:m" opt; do
  case $opt in
    t) tag="$OPTARG" ;;
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
if [ -z "$tag" ]; then
  echo "Error: tag is required" >&2
  usage
fi

if [ "$capturemarkdown" = true ]; then
  printf "### Importing this package\n\n" >> "$capturefile"
  printf '```\n' >> "$capturefile"
fi

printf -- "------------------------------------------------\n" >&2
printf "./dk0 --trial import-github-l2 --repo %s --tag %s --outdir %s/etc/dk/i/\n\n" "$repository" "$tag" "$PROJECTDIR"
if [ -n "$capturefile" ]; then
  printf "./dk0 --trial import-github-l2 --repo %s --tag %s --outdir etc/dk/i/\n" "$repository" "$tag" >> "$capturefile"
fi
printf -- "------------------------------------------------\n\n" >&2

if [ "$capturemarkdown" = true ]; then
    printf '```\n' >> "$capturefile"
fi
