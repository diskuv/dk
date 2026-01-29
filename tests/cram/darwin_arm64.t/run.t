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

The deterministic zip files created for dk0 objects don't contain symlinks, so `get-object`
will be an invalid CMake.app since its code signature will be broken.

  $ dk0 --trial -nosysinc -I ../etc/dk/v --trust-local-package CommonsBase_Build post-object CommonsBase_Build.CMake0.Generate@3.25.3 generator=Ninja 'args[]=-S' 'args[]=.' -d o/cmakegen
  [progress]: dla dk-releases:cmake-darwin_universal.zip size 80161981 ...
  [progress]:   dlb https://github.com/diskuv/dk/releases/download/cmake-3.25.2+ci2 ...
  [up-to-date] CommonsBase_Build.CMake0@3.25.3+bn-20250101000000 -s Release.Darwin_arm64

  $ file o/cmake/CMake.app/Contents/bin/cmake
  o/cmake/CMake.app/Contents/bin/cmake: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64]
  o/cmake/CMake.app/Contents/bin/cmake (for architecture x86_64):	Mach-O 64-bit executable x86_64
  o/cmake/CMake.app/Contents/bin/cmake (for architecture arm64):	Mach-O 64-bit executable arm64

macOS will popup a warning when trying to run the invalid CMake.app
  $ o/cmake/CMake.app/Contents/bin/cmake --version
  27209 Killed: 9               o/cmake/CMake.app/Contents/bin/cmake --version
  [137]
