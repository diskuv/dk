#!/bin/sh
set -euf

# parse options
start_package=CommonsBase_Std
git_remote=origin
allow_unknown_files=false
usage() {
  echo "Usage: rerelease-gh.sh [-g git_remote] [-s start_package] [-u]" >&2
  echo "Example: rerelease-gh.sh -g origin -s CommonsBase_Std" >&2
  echo "Options:" >&2
  echo "  -g REMOTE: The git remote to push the new tag to. Default is 'origin'." >&2
  echo "  -s PKG: The package to start from when re-releasing. Default is 'CommonsBase_Std'." >&2
  echo "  -u: Allow files unknown to git." >&2
  exit 1
}
while getopts "g:s:u" opt; do
  case $opt in
    g) git_remote="$OPTARG" ;;
    s) start_package="$OPTARG" ;;
    u) allow_unknown_files=true ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

# Function to check for uncommitted changes
check_for_changes() {
    if [ "$allow_unknown_files" = "true" ]; then
        if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
            echo "Error: Uncommitted changes detected. Please commit or stash your changes."
            git status --porcelain --untracked-files=no
            exit 1
        fi
    elif [ -n "$(git status --porcelain)" ]; then
        echo "Error: Uncommitted/untracked changes detected. Please commit or stash your changes."
        git status --porcelain
        exit 1
    fi
}

# ask the user to confirm that GitHub job has finished. allow the user to abort.
confirm_ci_finish() {
  confirm_ci_finish_package="$1"
  printf "\nWait until the GitHub %s job completes, then press y to continue or anything else to abort. (y/n) " "$confirm_ci_finish_package"
  read -r answer
  case "$answer" in
    y|Y) ;;
    *) echo "Aborting. Use '-g $git_remote -s $confirm_ci_finish_package' to retry." >&2; exit 1 ;;
  esac
}

dopush() {
  dopush_package="$1"
  ts=2.5.$(date -u +%Y%m%d%H%M)
  tag="${ts}+${dopush_package}"
  printf "\nWill tag and push release %s to git remote '%s'. Proceed? (y/n) " "$tag" "$git_remote"
  read -r answer
  case "$answer" in
    y|Y) ;;
    *) echo "Aborting. Use '-g $git_remote -s $dopush_package' to retry." >&2; exit 1 ;;
  esac

  # GitHub Actions is wonky if there are multiple tags on the same commit.
  # Mitigate with empty commit.
  check_for_changes
  git commit --allow-empty -m "Release $tag"  
  git tag "$tag"

  git push "$git_remote" main:V2_5
  git push "$git_remote" "$tag"
  confirm_ci_finish "$dopush_package"
}

do_CommonsBase_Std() {
  dopush CommonsBase-Std
}
do_CommonsBase_Build() {
  dopush CommonsBase-Build
}
do_CommonsBase_LLVM() {
  dopush CommonsBase-LLVM
}
do_CommonsBase_GNU() {
  dopush CommonsBase-GNU
}
do_NotMitEdu_Kerberos() {
  dopush NotMitEdu-Kerberos
}
do_NotMatveevKondratyev_Libinotify() {
  dopush NotMatveevKondratyev-Libinotify
}
do_CommonsBase_Win32() {
  dopush CommonsBase-Win32
}
do_NotInriaCaml_Std() {
  dopush NotInriaCaml-Std
}
do_NotGoogleDev_OR() {
  dopush NotGoogleDev-OR
}
do_NotInriaParkas_Caml() {
  dopush NotInriaParkas-Caml
}

# TODO: When dk0 gets arrows, we should statically get the package dependency
# graph and do the topological sort automatically.
case "$start_package" in
  CommonsBase_Std) 
    do_CommonsBase_Std
    do_CommonsBase_Build
    do_CommonsBase_LLVM
    do_CommonsBase_GNU
    do_NotMatveevKondratyev_Libinotify
    do_NotMitEdu_Kerberos
    do_CommonsBase_Win32
    do_NotInriaCaml_Std
    do_NotGoogleDev_OR
    do_NotInriaParkas_Caml ;;
  CommonsBase_Build)
    do_CommonsBase_Build
    do_CommonsBase_LLVM
    do_CommonsBase_GNU
    do_NotMatveevKondratyev_Libinotify
    do_NotMitEdu_Kerberos
    do_CommonsBase_Win32
    do_NotInriaCaml_Std
    do_NotGoogleDev_OR
    do_NotInriaParkas_Caml ;;
  CommonsBase_LLVM)
    do_CommonsBase_LLVM
    do_CommonsBase_GNU
    do_NotMatveevKondratyev_Libinotify
    do_NotMitEdu_Kerberos
    do_CommonsBase_Win32
    do_NotInriaCaml_Std
    do_NotGoogleDev_OR
    do_NotInriaParkas_Caml ;;
  CommonsBase_GNU)
    do_CommonsBase_GNU
    do_NotMatveevKondratyev_Libinotify
    do_NotMitEdu_Kerberos
    do_CommonsBase_Win32
    do_NotInriaCaml_Std
    do_NotGoogleDev_OR
    do_NotInriaParkas_Caml ;;
  NotMatveevKondratyev_Libinotify)
    do_NotMatveevKondratyev_Libinotify
    do_NotMitEdu_Kerberos
    do_CommonsBase_Win32
    do_NotInriaCaml_Std
    do_NotGoogleDev_OR
    do_NotInriaParkas_Caml ;;
  NotMitEdu_Kerberos)
    do_NotMitEdu_Kerberos
    do_CommonsBase_Win32
    do_NotInriaCaml_Std
    do_NotGoogleDev_OR
    do_NotInriaParkas_Caml ;;
  CommonsBase_Win32)
    do_CommonsBase_Win32
    do_NotInriaCaml_Std
    do_NotGoogleDev_OR
    do_NotInriaParkas_Caml ;;
  NotInriaCaml_Std)
    do_NotInriaCaml_Std
    do_NotGoogleDev_OR
    do_NotInriaParkas_Caml ;;
  NotGoogleDev_OR)
    do_NotGoogleDev_OR
    do_NotInriaParkas_Caml ;;
  NotInriaParkas_Caml)
    do_NotInriaParkas_Caml ;;
  *) echo "Error: unknown package $start_package. Supported packages: CommonsBase_Std, CommonsBase_Build, NotGoogleDev_OR, NotInriaParkas_Caml" >&2; exit 1 ;;
esac

echo '

Now that you have finished rebuilding the packages, you must:

1. Import the packages locally. The GitHub job summary will have
   copy-and-paste import commands; the imports validate
   GitHub attestations.
2. Run the cram tests with ./maintenance/test-cram.sh
3. Commit and push the imported packages in etc/dk/i.
'