Distribution for CommonsBase_Build

--- Assets ---

  $ get-asset CommonsBase_Build.CMake0.Bundle@3.25.3 -p cmake-darwin_universal.zip -f ${RUNTIME}/a1
  [pass] asset:CommonsBase_Build.CMake0.Bundle@3.25.3+bn-20250101000000:cmake-darwin_universal.zip
  $ get-asset CommonsBase_Build.CMake0.Bundle@3.25.3 -p cmake-linux_arm64.zip -f ${RUNTIME}/a2
  [pass] asset:CommonsBase_Build.CMake0.Bundle@3.25.3+bn-20250101000000:cmake-linux_arm64.zip
  $ get-asset CommonsBase_Build.CMake0.Bundle@3.25.3 -p cmake-linux_x86_64.zip -f ${RUNTIME}/a3
  [pass] asset:CommonsBase_Build.CMake0.Bundle@3.25.3+bn-20250101000000:cmake-linux_x86_64.zip
  $ get-asset CommonsBase_Build.CMake0.Bundle@3.25.3 -p cmake-linux_x86.zip -f ${RUNTIME}/a4
  [pass] asset:CommonsBase_Build.CMake0.Bundle@3.25.3+bn-20250101000000:cmake-linux_x86.zip
  $ get-asset CommonsBase_Build.CMake0.Bundle@3.25.3 -p cmake-3.25.3-windows-x86_64.zip -f ${RUNTIME}/a5
  [pass] asset:CommonsBase_Build.CMake0.Bundle@3.25.3+bn-20250101000000:cmake-3.25.3-windows-x86_64.zip
  $ get-asset CommonsBase_Build.CMake0.Bundle@3.25.3 -p cmake-3.25.3-windows-i386.zip -f ${RUNTIME}/a6
  [pass] asset:CommonsBase_Build.CMake0.Bundle@3.25.3+bn-20250101000000:cmake-3.25.3-windows-i386.zip
  $ get-asset CommonsBase_Build.CMake0.Bundle@3.25.3 -p cmake-3.25.3-windows-arm64.zip -f ${RUNTIME}/a7
  [pass] asset:CommonsBase_Build.CMake0.Bundle@3.25.3+bn-20250101000000:cmake-3.25.3-windows-arm64.zip

--- Rules ---

  $ run CommonsBase_Build.CMake0.Build@3.25.3 installdir=${RUNTIME}/i/llama-cpp
  >   'mirrors[]=https://github.com/ggml-org/llama.cpp/archive/refs/tags'
  >   'urlpath=b7974.zip#be9d624603e39cd4edee5fa85e8812eb8e1393537c8e4e4629bc4bd016388053,29881192'
  >   'nstrip=1'
  >   'gargs[]=-DBUILD_SHARED_LIBS:BOOL=OFF' 'gargs[]=-DCMAKE_BUILD_TYPE=Release'
  >   'bargs[]=--config' 'bargs[]=Release'
  >   'iargs[]=--config' 'iargs[]=Release'
  >   'exe[]=bin/*'
  >   'outexe[]=bin/llama-quantize'
  >   'outrmglob[]=test-*' 'outrmglob[]=*.py' 'outrmglob[]=llama-[a-p]*' 'outrmglob[]=llama-[r-z]*'
  >   'outrmexact[]=include' 'outrmexact[]=lib'
  [pass]
--- Objects ---

  $ get-object CommonsBase_Build.Ninja0@1.12.1 -s Release.Windows_arm64 -f ${RUNTIME}/Windows_arm64-Ninja0-1.12.1.zip
  [pass] object:o7s5p7woasm43fqwzc45l2o2ht57bwl2z2aehy2zjix7bnqf3x32a:CommonsBase_Build.Ninja0@1.12.1
  $ get-object CommonsBase_Build.Ninja0@1.12.1 -s Release.Windows_x86_64 -f ${RUNTIME}/Windows_x86_64-Ninja0-1.12.1.zip
  [pass] object:oarosxthtrgkstvvchonglc2p7aj3vp7pzygjfo77xynsbdw35gzq:CommonsBase_Build.Ninja0@1.12.1
  $ get-object CommonsBase_Build.Ninja0@1.12.1 -s Release.Darwin_arm64 -f ${RUNTIME}/Darwin_arm64-Ninja0-1.12.1.zip
  [pass] object:o3jk5lsvsix5tbyupm6tcm2eng4jmofier7jamc2oakzpz57hrbhq:CommonsBase_Build.Ninja0@1.12.1
  $ get-object CommonsBase_Build.Ninja0@1.12.1 -s Release.Darwin_x86_64 -f ${RUNTIME}/Darwin_x86_64-Ninja0-1.12.1.zip
  [pass] object:otuu72s7zfjqbynrqfrebtzmrt4aegp6mxhoxxngbhs32kot2nkoa:CommonsBase_Build.Ninja0@1.12.1
  $ get-object CommonsBase_Build.Ninja0@1.12.1 -s Release.Linux_x86 -f ${RUNTIME}/Linux_x86-Ninja0-1.12.1.zip
  [pass] object:ouffxf4brvk527rrf5trkjby5dpn3pp6xt3gfojng5th6djp5xbmq:CommonsBase_Build.Ninja0@1.12.1
  $ get-object CommonsBase_Build.Ninja0@1.12.1 -s Release.Linux_x86_64 -f ${RUNTIME}/Linux_x86_64-Ninja0-1.12.1.zip
  [pass] object:okwlfh53frfg6kerogiq2genhsschyvqgjwcyawrgfw4tdy6rodta:CommonsBase_Build.Ninja0@1.12.1
  $ get-object CommonsBase_Build.Ninja0@1.12.1 -s Release.Linux_arm64 -f ${RUNTIME}/Linux_arm64-Ninja0-1.12.1.zip
  [pass] object:ofhgsaxo2r7rbwufyljjllz2vpwvicworoyafdf3dvoeqvx4mevua:CommonsBase_Build.Ninja0@1.12.1
