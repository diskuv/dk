=================
CommonsBase_Build
=================

Ninja0
------

  $ dk0 --trial -nosysinc -I ../etc/dk/v --trust-local-package CommonsBase_Build get-object CommonsBase_Build.Ninja0@1.12.1 -s Release.Darwin_arm64 -m ./ninja.exe -f o/ninja.exe
  [signify] New build key pair in t/k/build.pub and t/k/build.sec ...
  [signify] Distribute key pair among trusted coworkers only!
  [progress]: dla ninja-build:ninja-mac.zip size 281130 ...
  [progress]:   dlb https://github.com/ninja-build/ninja/releases/download/v1.12.1 ...
  [up-to-date] CommonsBase_Build.Ninja0@1.12.1+bn-20250101000000 -s Release.Darwin_arm64

  $ file o/ninja.exe
  o/ninja.exe: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64:Mach-O 64-bit executable arm64]
  o/ninja.exe (for architecture x86_64):	Mach-O 64-bit executable x86_64
  o/ninja.exe (for architecture arm64):	Mach-O 64-bit executable arm64

  $ ./o/ninja.exe --version
  1.12.1

CMake0
------

  $ dk0 --trial -nosysinc -I ../etc/dk/v --trust-local-package CommonsBase_Build run CommonsBase_Build.CMake0.Build@3.25.3 'src[]=*.c' 'src[]=CMakeLists.txt' 'out[]=bin/sample' 'iargs[]=--verbose' 'installdir=install' 'exe[]=bin/*'
  [progress]: dla dk-releases:cmake-darwin_universal.zip size 80161981 ...
  [progress]:   dlb https://github.com/diskuv/dk/releases/download/cmake-3.25.2+ci2 ...
  [progress]: dla dk-c-root:main.c size 91 ...
  [progress]:   dlb cell://root ...
  [progress]: dla dk-c-root:CMakeLists.txt size 108 ...
  [progress]:   dlb cell://root ...
  done cmake build.

.  $ cat t/p/*/*/l/Release.Agnostic/stdout1.log
.  $ cat t/p/*/*/l/Release.Agnostic/stdout2.log
.  $ cat t/p/*/*/l/Release.Agnostic/stdout3.log

.  show errors from cmake (there should be none)
.  1: generate (cmake -G)
.  2: build (cmake --build)
.  3: install (cmake --install)
  $ cat t/p/*/*/l/Release.Agnostic/stderr1.log
  $ cat t/p/*/*/l/Release.Agnostic/stderr2.log
  $ cat t/p/*/*/l/Release.Agnostic/stderr3.log

  $ install/bin/sample
  success cram darwin_arm64.t!
