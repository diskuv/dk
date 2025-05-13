# signify

## Creating a new minor or major version

Please read <https://www.openbsd.org/papers/bsdcan-signify.html> for how to do key rotations.
The MlFront_Signify library has a detailed guide as well.

FIRST, get the `mlfront-signify` executable from <https://gitlab.com/dkml/build-tools/MlFront/-/releases>.

SECOND, decide whether the next version will be a minor upgrade or a major upgrade.
If you don't know yet, use a minor version upgrade. Then, when a major version upgrade is needed, the
minor version upgrade may be a change that does nothing except change the `VER` (step THREE) and
`dk_distribution_next_version` field (step FOUR) to be a major version upgrade.

THREE:

```sh
VER=2.4 # change the version number during a key rotation
SIGNIFY=mlfront-signify # you should be able to use OpenBSD signify as well (untested)
"$SIGNIFY" -G -c "dk $VER: signify -G -p etc/signify/dk-$VER.pub -s build/dk-$VER.sec" -p etc/signify/dk-$VER.pub -s build/dk-$VER.sec
```

FOUR:

1. Save the `build/dk-*.sec` secret key securely, and delete it from the filesystem.
2. Make a new version branch (ex. 2.4) for dksdk-coder and dksdk-cmake.
3. In dksdk-coder's `src/DkCoder_Std/PublicKeys.ml`:
   1. Copy the `dk_distribution_next_pubkey` into `dk_distribution_current_pubkey`.
   2. Copy the newly generated `dk-*.pub` into `dk_distribution_next_pubkey`.
   3. Set `dk_distribution_next_version` to whatever `VER` you used above.
