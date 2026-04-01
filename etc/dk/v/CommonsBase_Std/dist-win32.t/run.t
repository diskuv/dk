# Distribution for CommonsBase_Std

## CommonsBase_Std.Apparatus@0.1.0

We'll make a nano-sized tarball for testing the tarball extraction rules.
... The tarball contains a single file "somefile" with the content "hello world".
... The tarball was created with GNU tar on Linux with the command `tar -cf nano.tar somefile`.
  % return unified.asset { name="Nano", file="nano.tar" }
  asset
  10240
  sha256
  16369153e0e1ebb4dbcbd38c11b782dfe418b30fe6156b7b00015ba6c741452a

## CommonsBase_Std.Extract.F_Untar@0.1.0

This is a free rule that untars a tar, tar.gz, tar.xz or tar.bz2 file.

### Configurations

One of the following sets of options must be provided:
- tarmodver= tarassetpath= modver= paths[]=

### Options
- tarmodver=CommonsBase_Std.Apparatus.Nano@0.1.0
  The bundle containing the tar, tar.gz, tar.xz or tar.bz2 file.
- tarassetpath=nano.tar
  The asset path within the bundle of the tar, tar.gz, tar.xz or tar.bz2
  file to extract.
- modver=OurTest_Std.Extract@0.1.0
  The MODULE@VERSION of the form object that will contain the extracted files.
  The slot for the form object will be `Release.Agnostic`.
- paths[]=README.md
  All of the extracted paths.
  A future version may extract only the specified paths,
  but for now we extract all files and expect you to declare them all.

### FAQ

#### Q1: Platforms?
On macOS the /usr/bin/tar system binary is used.
On Linux the toybox tar command is fetched from an asset and used.
On Windows the 7z.exe from S7z command is fetched from an asset and used.
Also, for F_TarToZip: (macOS) /usr/bin/zip. (Others) the S7z object.

#### Q2: There is no way to filter which files I want.
*FUTURE* This rule will be renamed to CommonsBase_Std.Extract0, and the new CommonsBase_Std.Extract
will run CommonsBase_Std.Fd on the extracted files to filter them. The split is because
CommonsBase_Std.Fd requires CommonsBase_Std.Extract0.

### Examples

  $ post-object CommonsBase_Std.Extract.F_Untar@0.1.0 -f ${RUNTIME}/Extract.F_Untar.untar.zip
  >   modver=OurTest_Std.CommonsBase.Std.Extract.F_Untar@0.1.0
  >   tarmodver=CommonsBase_Std.Apparatus.Nano@0.1.0 tarassetpath=nano.tar
  >   'paths[]=somefile'
  [pass] object:oyxq47yh44ljkjgmchpx3r77qdolaj723q7u5vi4hpvij2m6xgq4q:OurTest_Std.CommonsBase.Std.Extract.F_Untar@0.1.0

## CommonsBase_Std.Extract.F_TarToZip@0.1.0

-- (Free rule) Extracts a tar, tar.gz, tar.xz or tar.bz2 file and then re-compresses it
-- to a .zip file which has first-class support in the dk build system.
### Configurations
One of the following sets of options must be provided:
- tarmodver= tarassetpath= modver=

### Options
-  tarmodver=CommonsBase_Std.Apparatus.Nano@0.1.0
   The bundle containing the tar, tar.gz, tar.xz or tar.bz2 file.
-  tarassetpath=nano.tar
   The asset path within the bundle of the tar, tar.gz, tar.xz or tar.bz2
   file to extract.
-  modver=OurTest_Std.Extract@0.1.0
   The MODULE@VERSION of the form object that will contain the "output.zip" file.
   The slot for the form object will be `Release.Agnostic`.

### FAQ

#### Q1: Platforms?
On macOS the /usr/bin/tar system binary is used.
On Linux the toybox tar command is fetched from an asset and used.
On Windows the 7z.exe from S7z command is fetched from an asset and used.

On macOS: /usr/bin/zip
Others: the S7z object

### Examples

  $ post-object CommonsBase_Std.Extract.F_TarToZip@0.1.0 -f ${RUNTIME}/Extract.F_TarToZip.tartozip.zip
  >   tarmodver=CommonsBase_Std.Apparatus.Nano@0.1.0 tarassetpath=nano.tar
  >   modver=OurTest_Std.CommonsBase.Std.Extract.F_TarToZip@0.1.0
  [pass] object:om7kvzubdb6m5lfxm5ic6mf4zre56qvnlt7zqaac2tc3uz72hsrma:OurTest_Std.CommonsBase.Std.Extract.F_TarToZip@0.1.0

## CommonsBase_Std.S7z.S7zr@25.1.0
  $ get-object CommonsBase_Std.S7z.S7zr@25.1.0 -s Release.Windows_x86_64 -f ${RUNTIME}/Windows_x86_64-S7z.S7zr-25.1.0.zip
  [pass] object:o6mbbz5lppxk7lltlewdl3ukysykgeyrlpsdhjgcldhmrzvo4pueq:CommonsBase_Std.S7z.S7zr@25.1.0

## CommonsBase_Std.S7z.Windows7zExe@25.1.0
  $ get-object CommonsBase_Std.S7z.Windows7zExe@25.1.0 -s Release.Windows_x86_64 -f ${RUNTIME}/Windows_x86_64-S7z.Windows7zExe-25.1.0.zip
  [pass] object:o3owhcetqrbifkvtsb2igs5jcqun4vvy737nryi2ufcebugo7qn7q:CommonsBase_Std.S7z.Windows7zExe@25.1.0

## CommonsBase_Std.Coreutils@0.2.2
  $ get-object CommonsBase_Std.Coreutils@0.2.2 -s Release.Windows_x86 -f ${RUNTIME}/Windows_x86-Coreutils-0.2.2.zip
  [pass] object:o7gntafiirl4vibmnv34tc42eqtgh72ccsnnvqwvlttf27k4hf2tq:CommonsBase_Std.Coreutils@0.2.2
  $ get-object CommonsBase_Std.Coreutils@0.2.2 -s Release.Windows_x86_64 -f ${RUNTIME}/Windows_x86_64-Coreutils-0.2.2.zip
  [pass] object:o2npj4ay7c5zfbegeolrrtvgxciwvdi7mly4wjgeu2ibqgnsuqpja:CommonsBase_Std.Coreutils@0.2.2
  $ get-object CommonsBase_Std.Coreutils@0.2.2 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-Coreutils-0.2.2.zip
  [pass] object:obcu2tfsu7kfxosyejj3anoqsyiphz5ls7aptrfggaknydh5j7pta:CommonsBase_Std.Coreutils@0.2.2
  $ get-object CommonsBase_Std.Coreutils@0.2.2 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-Coreutils-0.2.2.zip
  [pass] object:olw7vbbketz3zeoqa4vkikeun7hbwejatareohhpg6cnlxw5qqohq:CommonsBase_Std.Coreutils@0.2.2
  $ get-object CommonsBase_Std.Coreutils@0.2.2 -s Release.Linux_x86 -f ${RUNTIME}/Linux_x86-Coreutils-0.2.2.zip
  [pass] object:orbpkvubnlvghxbzwr4fhcgzuvw7hyhn3n2sygck527ow5yjzsjzq:CommonsBase_Std.Coreutils@0.2.2
  $ get-object CommonsBase_Std.Coreutils@0.2.2 -s Release.Linux_x86_64 -f ${RUNTIME}/Linux_x86_64-Coreutils-0.2.2.zip
  [pass] object:oug247u2tcxvroijdfyv42znb7qnt2ygrlrqw44crn6jlaethovaa:CommonsBase_Std.Coreutils@0.2.2

## CommonsBase_Std.Coreutils@0.6.0
  $ get-object CommonsBase_Std.Coreutils@0.6.0 -s Release.Windows_x86 -f ${RUNTIME}/Windows_x86-Coreutils-0.6.0.zip
  [pass] object:ont7ofo7gfvvjmnrcbaqamnuq25xlwvthjgh5e2w6w65xbfythsda:CommonsBase_Std.Coreutils@0.6.0
  $ get-object CommonsBase_Std.Coreutils@0.6.0 -s Release.Windows_x86_64 -f ${RUNTIME}/Windows_x86_64-Coreutils-0.6.0.zip
  [pass] object:oei7stxtfiulvf5d43vgceu52iwfkriwlkovfwagkyza6iisfh3yq:CommonsBase_Std.Coreutils@0.6.0
  $ get-object CommonsBase_Std.Coreutils@0.6.0 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-Coreutils-0.6.0.zip
  [pass] object:o7vxqdcyw5ob33ncqtep4qwlmpdfs3d4l446chiftodnwd34cf37a:CommonsBase_Std.Coreutils@0.6.0
  $ get-object CommonsBase_Std.Coreutils@0.6.0 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-Coreutils-0.6.0.zip
  [pass] object:oohroq4h3lm2xpwc2mofm5hbqjkzbmnyzihc5aoggrvl3f72c3qra:CommonsBase_Std.Coreutils@0.6.0
  $ get-object CommonsBase_Std.Coreutils@0.6.0 -s Release.Linux_x86 -f ${RUNTIME}/Linux_x86-Coreutils-0.6.0.zip
  [pass] object:ojoe2g3duui2nrhf6mb3nbf66443kvg5q7nstllo2piihv2admyxq:CommonsBase_Std.Coreutils@0.6.0
  $ get-object CommonsBase_Std.Coreutils@0.6.0 -s Release.Linux_x86_64 -f ${RUNTIME}/Linux_x86_64-Coreutils-0.6.0.zip
  [pass] object:odukgoi3kx2eduawtawhxjgtok3jfqkgahcv7ojcqzit7vsmjb43a:CommonsBase_Std.Coreutils@0.6.0

## CommonsBase_Std.S7z@25.1.0
  $ get-object CommonsBase_Std.S7z@25.1.0 -s Release.Windows_x86 -f ${RUNTIME}/Windows_x86-S7z-25.1.0.zip
  [pass] object:owduwtodu3snw2mupnvn2lifstyx4xxbffptirtuan4qhz5fsgf3q:CommonsBase_Std.S7z@25.1.0
  $ get-object CommonsBase_Std.S7z@25.1.0 -s Release.Windows_x86_64 -f ${RUNTIME}/Windows_x86_64-S7z-25.1.0.zip
  [pass] object:oajm737ct53tygsrvbkcaol5duxc6cbk6vbfybpiledixazwggkjq:CommonsBase_Std.S7z@25.1.0
  $ get-object CommonsBase_Std.S7z@25.1.0 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-S7z-25.1.0.zip
  [pass] object:or56pwongiaz4o2lkzddel7vsfxmefityinhgyaq3zluursivw7sq:CommonsBase_Std.S7z@25.1.0
  $ get-object CommonsBase_Std.S7z@25.1.0 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-S7z-25.1.0.zip
  [pass] object:oi5cze3db2dmdp7n4u4srcxp7ojlqwmkyhsdcpzkl5fyzc2c7c2ia:CommonsBase_Std.S7z@25.1.0
  $ get-object CommonsBase_Std.S7z@25.1.0 -s Release.Linux_x86 -f ${RUNTIME}/Linux_x86-S7z-25.1.0.zip
  [pass] object:on5rxjdotzx4thg5k7g2zillxi5uccfafenooljpuybg3ckmao4ga:CommonsBase_Std.S7z@25.1.0
  $ get-object CommonsBase_Std.S7z@25.1.0 -s Release.Linux_x86_64 -f ${RUNTIME}/Linux_x86_64-S7z-25.1.0.zip
  [pass] object:or4nuqg4jceexyskihrl4ieac7wh6zvzj2ec37ahkxtps6ppmgtnq:CommonsBase_Std.S7z@25.1.0

## CommonsBase_Std.Fd@10.3.0
  $ get-object CommonsBase_Std.Fd@10.3.0 -s Release.Windows_x86 -f ${RUNTIME}/Windows_x86-Fd-10.3.0.zip
  [pass] object:o2b2kqcwtzv6lvyhhlpyt3c5h4ta55soiqz65iwh5adhfxi7e7bha:CommonsBase_Std.Fd@10.3.0
  $ get-object CommonsBase_Std.Fd@10.3.0 -s Release.Windows_x86_64 -f ${RUNTIME}/Windows_x86_64-Fd-10.3.0.zip
  [pass] object:og64qa5u2b7o6m74qtzit2s7igwrrazmgnu7rvqvkodiqt72acwma:CommonsBase_Std.Fd@10.3.0
  $ get-object CommonsBase_Std.Fd@10.3.0 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-Fd-10.3.0.zip
  [pass] object:oec26gwkarphvmy65f5szgai2jtfopzhppjvabmwof2obsdzgitcq:CommonsBase_Std.Fd@10.3.0
  $ get-object CommonsBase_Std.Fd@10.3.0 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-Fd-10.3.0.zip
  [pass] object:owuchj6gjfg4cedwvinhnd3cmwthotmt4tc75rjjdd65mu4bkk7ga:CommonsBase_Std.Fd@10.3.0
  $ get-object CommonsBase_Std.Fd@10.3.0 -s Release.Linux_x86 -f ${RUNTIME}/Linux_x86-Fd-10.3.0.zip
  [pass] object:ofwwxm32kqvnihhudpm4ivgouk27z4dlxfusalkh37r7ze4yl52qa:CommonsBase_Std.Fd@10.3.0
  $ get-object CommonsBase_Std.Fd@10.3.0 -s Release.Linux_x86_64 -f ${RUNTIME}/Linux_x86_64-Fd-10.3.0.zip
  [pass] object:ohl5svgnkijzgisrq2j34656jymrz7sqbtewx2r7zmlsiwbgea6xa:CommonsBase_Std.Fd@10.3.0

## CommonsBase_Std.Toybox@0.8.9
  $ get-object CommonsBase_Std.Toybox@0.8.9 -s Release.Linux_arm64 -f ${RUNTIME}/Linux_arm64-Toybox-0.8.9.zip
  [pass] object:o4mzseh7byym2vyns5wsawvqu5qfh3ktlog67pxdqw7vilgrdgo7q:CommonsBase_Std.Toybox@0.8.9
  $ get-object CommonsBase_Std.Toybox@0.8.9 -s Release.Linux_x86_64 -f ${RUNTIME}/Linux_x86_64-Toybox-0.8.9.zip
  [pass] object:ojt47gnivpaxi74ecog3ha6eigs63di5tg2d62v4o3kuiobblgfza:CommonsBase_Std.Toybox@0.8.9
  $ get-object CommonsBase_Std.Toybox@0.8.9 -s Release.Linux_x86 -f ${RUNTIME}/Linux_x86-Toybox-0.8.9.zip
  [pass] object:osk2rjv7tarwm6sbplfvvt7b7w3fvrjnlwapbsuqgofjfi2tqyjwq:CommonsBase_Std.Toybox@0.8.9
