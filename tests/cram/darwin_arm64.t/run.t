-----------------
CommonsBase_Build
-----------------

Ninja

  $ dk0 --trial -nosysinc -I ../etc/dk/v --trust-local-package CommonsBase_Build get-object CommonsBase_Build.Ninja@1.12.1 -s Release.Darwin_arm64 -m ./ninja.exe -f o/ninja.exe
  [signify] New build key pair in t/k/build.pub and t/k/build.sec ...
  [signify] Distribute key pair among trusted coworkers only!
  [progress]: dla ninja-build:ninja-mac.zip size 281130 ...
  [progress]:   dlb https://github.com/ninja-build/ninja/releases/download/v1.12.1 ...
  [up-to-date] CommonsBase_Build.Ninja@1.12.1+bn-20250101000000 -s Release.Darwin_arm64

  $ file o/ninja.exe
  o/ninja.exe: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64:Mach-O 64-bit executable arm64]
  o/ninja.exe (for architecture x86_64):	Mach-O 64-bit executable x86_64
  o/ninja.exe (for architecture arm64):	Mach-O 64-bit executable arm64
  $ ./o/ninja.exe --version
  1.12.1
