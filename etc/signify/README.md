# signify

## Generating a new key

Please read <https://www.openbsd.org/papers/bsdcan-signify.html> for how to do key rotations.
The MlFront_Signify library has a detailed guide as well.

Get the `mlfront-signify` executables from <https://gitlab.com/dkml/build-tools/MlFront/-/releases>.

```sh
VER=2.4 # change the version number during a key rotation
SIGNIFY=mlfront-signify # you should be able to use OpenBSD signify as well (untested)
"$SIGNIFY" -G -c "dk $VER: signify -G -p etc/signify/dk-$VER.pub -s build/dk-$VER.sec" -p etc/signify/dk-$VER.pub -s build/dk-$VER.sec
```
