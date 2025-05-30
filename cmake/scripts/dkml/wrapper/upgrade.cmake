##########################################################################
# File: dkcoder/cmake/scripts/dkml/wrapper/upgrade.cmake                  #
#                                                                        #
# Copyright 2023 Diskuv, Inc.                                            #
#                                                                        #
# Licensed under the Open Software License version 3.0                   #
# (the "License"); you may not use this file except in compliance        #
# with the License. You may obtain a copy of the License at              #
#                                                                        #
#     https://opensource.org/license/osl-3-0-php/                        #
#                                                                        #
##########################################################################

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")
    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()
    message(${ARG_MODE} [[usage: ./dk dkml.wrapper.upgrade

Upgrade ./dk and ./dk.cmd.

If there is a .git/ directory and no .gitattributes then a 
default .gitattributes configuration file is added.

And if there is a .git/ directory the .gitattributes, ./dk
and ./dk.cmd are added to Git.

Usage
=====

TLDR: Run the upgrade twice.

On Windows you may see an error when an upgrade includes an
update to ./dk.cmd. That is because Windows will:

1. Run a portion of the old ./dk.cmd
2. Save its position in ./dk.cmd
3. Do the upgrade of ./dk.cmd
4. "Continue" running the updated ./dk.cmd with the old (incorrect)
   position.

To avoid the problem, you should always upgrade once, then ignore any
error, and then run the upgrade again.

Arguments
=========

HELP
  Print this help message.

HERE
  Do the upgrade in the current directory rather than the
  directory that ./dk lives.
  This is useful as the first step in adding ./dk to a
  new project:
    git clone https://github.com/diskuv/dk.git
    dk/dk user.dkml.wrapper.upgrade HERE

DONE
  Remove the dk/ created by a prior invocation of:
    git clone https://github.com/diskuv/dk.git
  This is useful as the final step in adding ./dk to a
  new project.
]])
endfunction()

# BEGIN Removing old __dk-find-scripts.cmake
#   PROVENANCE: sh cmake/scripts/dkml/wrapper/upgrade.remove-old-dk-find-scripts.sh
set(old_dk_find_scripts_CKSUM256
"00c7eddfded923d2d73b0ec99407ac002d1d3dbb4366bc59a2a5a0a2dc0d5abe"
"022982a5b7343a6beefdff59a4dd0f92835f4b6cc89e7d0cf6e02cf4f074beb3"
"0262042853ef03d21161f5fd0abdf965fba2f8f093ebc5c5297f489ff661e9f4"
"0608f74ad4492830a7d4087cfd1a214c50ccb9863bead94504fc27591aa5dc78"
"072bf5c2f40fa078b5045cdc6067445933393f6bafa028708829fae432a605ec"
"08b473f97455fe6086b7b8b2d6efb3ed68c2d1f4bdb803a8d9365ba4e4081014"
"0ad159ca0cf16dd1b862fcfdb5022365de6b103610ecb1f808065e5b12697149"
"0afe036ff6c4732b93f0a0dcec6d5bf6606eb5ab63cce3d90915ec65750e9e91"
"0b873feef7f84af764d9349326c63d409c998faf41786dfad1c8daec59ccdf64"
"103e5beb835db6a4832dbfeebf2c6a5ed88599aa5d9a48dcda9aa3f237448a35"
"1561ec7dff49ab42c2b3011b95b09cf08ac6721e40b42fe3482fd47fac99777c"
"15f4f19c29b4ddcc4caf23171b8f840bb9cdbb15eeb549539930558973fae9a8"
"160a4af017ad5d82081421f3176bc6b255936a260430ad041ed7c5bea88ec6e1"
"17fb54aadafb129d835c757a5aa374a0b81f97d07d34cd0bca82655ae1b6f668"
"1b2ae3b1672c06b79c549959fb2274e8e245261f9b5855af4c2d34fee478d1af"
"1c64edbf3a4eb0f8d3d1a8cb7e91890aee8f8fc291309e190d96849eae05111b"
"1cc8d90ee79e0515762a0d457a28881b7eda911783c41d7788d3730bac124c56"
"1d62727ecd52d813d8f698bec3a335c34a169c4606cae74e099fddd72927ca98"
"20e3f1b583bfad39c0a86b82e1c13bb059b2814223696b84e208ad124598619c"
"221f7845f290a1ab447d6d1de785a7bbbbe221c88d7774982f89d4a2e4f8bdc6"
"22bf9a43151985f0a375da97b4511bc7a58993dde2810ed84746c0a1c23597d7"
"236eb6af53f1ff8b077dd4d015ddc9f71a38e135ab8b91761c4b6f6b02020829"
"23d6fe3c6f2d9a1c3e4d95636ba6059809019f2cdc6e10175a044484e208e9e0"
"2acc0b5f80e870d83adff2cbad2d69b27d97396cc2d26571786d343305284a78"
"2c12c647a60dc1d74ded10b69df4f36a0670854dcb17833f08151be716c7c14e"
"3250a0891c20e104651b001672c29fad2fc41b1d4d2243414a65ce04b01548e9"
"38c0b118762dd42ee91d504201fcbd641f5afbbfd6700d160f4b60c42a25d6b1"
"396f7f71c3b97a865ae008b2d94a122717736672a744e099691f7dcc8fcb8c9c"
"3b93cb01e337b276592f9b0675c25506b2fb7d77f433ae6e5e0c3ccd7d6849be"
"46f5e18d277ceb7e0f9a55ed378a5683da2558b6580f03ca89607aace7668768"
"482afa5c884a1e56e32f8405ac562421a10ac17e00eae22aa80dc232bcd98801"
"4857dfe208b38a91adb64d578a1f6d09becc421796588193b4315fa595fb414c"
"48694dbebcc8fd640f99ab96fdc5c172dedf78ea278c914619f8964f85fc8b4f"
"4b83fe5afe173f618bf0415da9c68f8c6dc516e08c7ba9b29307fc0ce3f592e7"
"4caed5f800ee48d875f577c8b225712aa69e7b4adee6dd3004936879ffb5edb9"
"4d053fd6a04d1096f01af5c78fcb8e19fbe0470b736048aea857e44ef726850d"
"4e55a8afb363075422a0f9eb374c9246f67e3d0372ad782ec0c5f5faebbd57b0"
"4e70d780b07cf2c62f76a4549f57b2d5f1743968e2744d8458a073a03630613d"
"52732b82a4aae66d8a12ca26e3f8c2bed5db24794a97c33d7b96a7aa73c49207"
"5758f125e9e9867010fd875579fb9a6d83dd9084efdeb3d42760f2e0bddf5942"
"58664f2c49ce71a5443e6a14954d93d44ffb27553142691a0270109aa84f772f"
"5868a0e653b475dcbed8a08b13f0e05965c1c7b93fa0a303ba239e9377656d1f"
"5a4c4307475552e1879fca1c221bb66235af2cb44b9ba8428134823530fbcf5a"
"5a975344bd2fbe3f4e46f134f93a3bb30ad569e6058dbe0dacdcbd155b231490"
"5bd7ff8dea526bc75f2c0ce9c99bab1a43820f77634f0e533d202997f7da80ea"
"5e456ab7fe8c4cd0621311c2b741eb1e318e651bd78cd289785c7a4f99319145"
"5e69c10651682ad210358d5f4d671b2c3d79d2e90133b50fff89c918828fd1a1"
"612af8209293bed3ee40abd05b1d43c67d1445d99a60bbb0fd0369543c2c28ed"
"63686e6e8805f6f92565a1fa6aea78aa4be2717b51ef159615fd9e7925254e20"
"63f8d4a5acf0006d82bf68736c8d90f13e2c610610bc2001808af1eda0fe7fcc"
"645bc1a907c49da858806bf8b1f48628000fea735144dc64b360cfceebd29488"
"654cb3a5df74c14efd9ab5b15090766d6e098d0b3856e0030d09bd2643dc0526"
"67567e374550a0eda12cf9555a48866365ec6393066ce0f07bf4952fac02c718"
"6792293e89756329eae8061b9ffca527ae573dfa2dd601b4b8f9cc48e1c0d457"
"687a8a7bc81651bd0585e3df7d3c2ff7606c98c39134a3f80bf3f01c91aef743"
"69c7af1efc0ee9963dc841e3860ae2df34b59cd21409fec16d5019a5315a588c"
"6de2dc5e4c0f244cf8ac6f0cb90756798232ee8f9a711d91abf1b3e6042456a6"
"6deecbaa9954a75156d405881b33568834231359e1b5bd43efadcbd3cfd23b96"
"6e45fcf7b97e2c89408d69c56a833f87d0de16fee049a6ac32508b36d6c11194"
"6ffd7079a01fd2bafcac89f9f2501b58bb30c0e6383f4b5bc088e544cf6adb58"
"733846401973a59d524519d1e0f56756bb35f02797a6c4a55ada8964f96f27a4"
"7409c9fa3277ed7780100c8f1078e0b9013d06c961ec4e4db384cf9125b1d553"
"7aa31d88f369a9ac3b86d4d37bf8ceec04884531d0f247f4f3925ea5cb16e088"
"7ab5df7a39ca9785c6e1e4449509872effb2e1e6280d2716f06cb9719a54205f"
"7b062aa3116edee62fce0ceceffad9e0958101992b997f50ebd5a5ea6a168e53"
"7bc5c41dd8f30e6d4b5c73ec5b4a4326cebbc95d6cc30673ef361d1474aeb13c"
"7c79dde302d42ea1ba37706624d80cc8d340022431f02093da7f018e05c3bce6"
"8343b4d4a6b7a2c20589fd039203825856741a01b6bea60b9c22cd35f437918b"
"87ea7913be878c1b9ad1518a260a8595479368baafb0d9c9026a40f7f49496b1"
"8a2d9be5f8787ceff3f7675b281f726c06b86fa4ee8384dd1432bf97ef3de3bc"
"8b47ddf560bb924ff043be1fa602ff251dd6d6b9343637c406957de9a638e270"
"8c39be7f18d9694ddff9d9e64f68fd8a2ac4cf1c273bcebbf7f03691d3364966"
"8e5cc3b1b9471689faa3d2a7f6641afbe1b2fbdb21642b8721e37b8b7510e1c5"
"912b1f1ed95dbb35759e31b5f435aae9d9c3682cc523dae837e95b7a23f23414"
"9301e588f114188311713af6aa156bedccaf595deafbe6991ab3cb71c005be31"
"982edcdc1a88ff5a79b9221b10dbed34ed32bf81be47749674ec86cdcc9acd29"
"9842a005ede35e13582a954ba1c115667bd1abdd3a67acd8795b997cbc080f7e"
"9beb25ab0e465349335a3280d5e3b950e8f89edab431ac9188b098992feb490b"
"9d0e50b192ea90b172a41ca714557604e51121769b3e9229ae440c0e04915262"
"9d23765bd0e43ab9e160cd81fd5f1a99756d888fa933b34a40aa9e88b1362efd"
"9dc85398fa9bf89958cf8b94b2bd4c5cae94a331af90592b4c6803b4999d9062"
"9dfb09604b8cae4c1202896766a1f2987b5982c5d8d67ff60c90cfcde883bec2"
"9ee82e897aff4516862b3ee8a349f094ccaab733d2f4a5c2e41655b07fd85fac"
"9f526c1b804dca423187dab8922989bd1e8aa97177eb6da454955ac477ac1cea"
"a0f7c0e089d914e709bab2a5e316413c10407a0fec197b26d67fa1247cab9a9f"
"a1b3372592a4ada8b1c2123c7803853d82508d49d0530428569b23eadeac6bd0"
"a2668cce9c9097fadf26a2fc41fbb6453a9b394342e514eb66c6b17890287c9d"
"a3173f79ba76886716e8a55b3f1367c7bb2ebd9b3fb2a9fafb13e24cba0f020b"
"a31dfdeb019e155f94b547769d3e0d63700292e35ca9a4c122d30fe090c83f71"
"a4d982c88c4f48b83ed0b62b2a043267041860f99b9110e4c80f651f97d2e12c"
"a62cddadd3615f8f21b0df474dc03355b05ea6003612d754f0f1c99cbf5d5137"
"a7364f446a7cdc980e1a92ff4361320fb445a0958fe440abe1392d9a6d81db2c"
"a8771418412bf0f1a73ec0b09491158f1b6cda592e5c2f5d63a1656578fde803"
"a9665cf9dd190cc1e8366541ed0452df2261d1dcccec73d58447a271b45217ef"
"a9b53e2501066b9b82449a6b317f92f1ab33ad69df8d99f03a8b9c9d0fd7bd95"
"a9c21a228ccc425ba603f5de9379746b54c2987a9d5bd9b816d5e22b125e99e6"
"ab6ac4e819afea1f0ba9c5abb87621603a9aea5435bf5f4b5f6c2e6a531a8e96"
"ae1858823722580ab45011b027df97e033c2ef4d3e0b6d745d65f33992797c73"
"af3a81a087e8a3d4843d7ccb7b7077a3f1ce99e905db33a49a2b57fa2f63df70"
"b03718fcab0ab061eb7d8e3c0f9defa79d7b2e63cb15056aa627c202ce9c7899"
"b04e30dd064af384962371fcd1a8a6977eac03e9813005cb3323d7355ebbfbf8"
"b0893cb8fcfc7d96827920ef574025b72f77ef73691351cea54d1ad9bd019e5c"
"b23e6433828f51230922970ec6ae9f58ff739a0a4f0fa9316134c3c2b925bdee"
"b29147c4983a6213df669305db6e89e144c93498f7e02989307871a62e06c441"
"b3c2263315131d69ef8ab8cc13d84848ee914122ab2143341923b32a6b3c6740"
"b4644befdae54b6cf04a75ea8c8d481400f8ec51527db29f653622b6b7e863e8"
"b4e732c586b207d63171c8f1f92b15c104410352dc7d4db5e73e1427f8a30d43"
"b56eda45d41fe951059a6418c3e74cafe79027dcb5a188f5f6a45d643033c416"
"b602ee08310d5df9d5b17a60de2954153e2efe9974a75b2a268b4648508a1cf7"
"b6c35b4feca5017068b297489ced25fabd612744ba2ed57ce4b58ded31305456"
"bad759cc4c0a4dec5dde7111cb02c1318e303ec877c5b3aef0efd543d998182e"
"bcc02624c54b982ebccbef8d12123bfb85e5b0418d3adef82b70d8e40794a9c9"
"bd9b4527280cde680d206ad922dd756e2328029ede1b4c200c2a6162839d0e4e"
"c029e1ecfe046a23ca09f0be69032067501af0fafc849291e7e17459b8323dfb"
"c161d9f84b43a368b6783a31e8d38b4c46c19074886e1c44dd77031284f019a0"
"c1dfc6ca51cb6f0a2660a52c99e0c98be025bd8d3eea183c657f947ba6189de8"
"c3c62eef95a179a06f6f5b75c3deefa791913051736acc041fa53db1e9c8d4e8"
"c5eb354117138fdfab306f4e46ac45f738e02152dc8d90dcf3ed1a62a2fefe90"
"c7cc42144873810ba727a4da5fcecc369e92ac997f2af2ad2bac0448cb3aaf9b"
"ca3944b08b33221ad567e15c9cf2bbd60d38b7c720eec6c23ec4230842ff33b4"
"cca02598412cbc567052d18116dcac332eb0dd2da15d46665f7ddb169fdea738"
"ccd70805fc81170ba509b85a642750a82e4e5887e3e3b376fcd9e61b5428af09"
"ce4471f56092ed846f15b9861f9f704648225c71a7feb694fd650418cb9e0de7"
"cf2261805f6ce691d2642cec342bd8fff0ef17956009ac6361ed40679b444504"
"d5c8302fae5a6aa654ea2c50f069a86d9e29d67fc73a7b66047b97c8b4dbfb6e"
"d7c23367e333ad0e7657eed2de2f52b2100d8ebe54252cfd7597cb761ec177f1"
"d80c109366b02567c1ebc69a3ff29a0b4934b22a420bebb9bae1e3fcaf0b0889"
"d9c1dccb36bd8ebb3a4c9348da7d3c7f43b9646c82319025738a7ab73d7392b5"
"dab902c2948afbff4da9f2d86d6760af260b37adc7c016fcf9e5a1856041af1a"
"db40b70b090c09a9909ffa7da8f1ea4c38e8e70007c5a557cec6bb6bcb6be9a8"
"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
"e7f21447c265d68213c0d74b7e3fc3958888ee42a5a05528c5a748e62a4c3a99"
"e8edf408a74dc15b52cf070b52e2799677d328fe049d7b9569a3eb3fa9801781"
"e91460c7edd9267cf18d73680124b7ac095028a42ddc00282ca8df5738b47fc6"
"eabf0b4dbc200e31767092cebb7601d602d42afcab1bcd4ac2e8c089f203fc80"
"eb22cce32933a3b5902cb9fdd30f890bd76cc6329904a7b27fec32eda78fe081"
"ec75ad665499fc37a2b3076ee3a148a3c218c7f649a474d1dd117d497564da9e"
"ee735dc693d6eac179f3004ac8fb770a375e7741fb245420348eeab947c92191"
"f21da85ea7b805ead733b4141529ea835cb8f6eddeb0c22c4adc51f862f21275"
"f272a0c8faa82ea6b29a830538382bf3fa6b3de537bc6502b85641acecea2fc2"
"f28cc9ee5e72d8275eff23d56ab93486fce3950d9fef1e32566a6b849969883f"
"f523a76accfc5b513a8c3c0ed80d82dec0ca810e13a2a13c8f1488c6d55f41f9"
"f676c8b3b100bc69c893cb1c277f2e62c94079e164a5ee231e792268393d6ff5"
"fa03a2f9b796b441d9a406ce1b663821537f155ffae44446d8682cc60f54202f"
"fb542fef2183f98caf3dd27c4db232092d44b78d3b92c9acb47fb7cd79887a15"
"fba404d218e1bf66849d2eddec49bec7dd02b771485d20b38ae0d27cf5013cde"
"fba565f53cdd73692ed2313003eff746f2386e1accf0b471db808cc6a0ff1563"
"fd68e3842428f71752a399775591815b27e369f93b7e762b378194e24e1b3e78")

set(old_dk_find_scripts_WIN32_CKSUM256)
# END Removing old __dk-find-scripts.cmake

function(run)
    # Support new IN_LIST if() operator
    cmake_policy(SET CMP0057 NEW)

    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;HERE;DONE" "" "")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    if(ARG_HERE AND ARG_DONE)
      help(MODE NOTICE)
      message(FATAL_ERROR "You cannot use both HERE and DONE arguments")
      return()
    endif()

    # <dkcoder>/cmake/scripts/dkml/wrapper/upgrade.cmake -> <dkcoder>
    cmake_path(GET CMAKE_CURRENT_FUNCTION_LIST_DIR PARENT_PATH d)
    cmake_path(GET d PARENT_PATH d)
    cmake_path(GET d PARENT_PATH d)
    cmake_path(GET d PARENT_PATH d)
    cmake_path(SET path_dk "dk")
    cmake_path(SET path_dkcmd "dk.cmd")
    cmake_path(SET path_gitattributes ".gitattributes")
    cmake_path(APPEND d ${path_dk} OUTPUT_VARIABLE file_dk)
    cmake_path(APPEND d ${path_dkcmd} OUTPUT_VARIABLE file_dkcmd)
    cmake_path(APPEND d ${path_gitattributes} OUTPUT_VARIABLE file_gitattributes)

    # validate
    if(NOT EXISTS ${file_dk})
      message(FATAL_ERROR "Missing 'dk' at expected ${file_dk}")
    endif()
    if(NOT EXISTS ${file_dkcmd})
      message(FATAL_ERROR "Missing 'dk.cmd' at expected ${file_dkcmd}")
    endif()

    # DONE?
    if(ARG_DONE)
      # we already checked that no [HERE] argument
      if(IS_DIRECTORY "${CMAKE_SOURCE_DIR}/dkcoder" AND IS_DIRECTORY "${CMAKE_SOURCE_DIR}/dkcoder/.git")
        file(REMOVE_RECURSE "${CMAKE_SOURCE_DIR}/dkcoder")
      endif()
      message(NOTICE [[

Congratulations. Let's get building!

  Announcements | https://twitter.com/diskuv
  DkML          | https://diskuv.com/dkmlbook/
  DkSDK         | https://diskuv.com/pricing/
  Second OCaml  | https://www.youtube.com/@diskuv/
]])
      return()
    endif()

    # destination
    set(dest "${CMAKE_SOURCE_DIR}")
    if(ARG_HERE)
      set(dest "${DKCODER_PWD}")
    endif()

    # install
    file(INSTALL "${file_dkcmd}"
        DESTINATION "${dest}"
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
    file(INSTALL "${file_dk}"
        DESTINATION "${dest}"
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    set(paths_ADDED "${path_dk}" "${path_dkcmd}")

    # deletions
    set(paths_DELETED)
    if(EXISTS "${dest}/cmake/scripts/__dk-find-scripts.cmake")
      file(SHA256 "${dest}/cmake/scripts/__dk-find-scripts.cmake" dkfindscriptscmake_cksum256)
      set(delete OFF)
      if(dkfindscriptscmake_cksum256 IN_LIST old_dk_find_scripts_CKSUM256)
        set(delete ON)
      endif()
      if(delete)
        file(REMOVE "${dest}/cmake/scripts/__dk-find-scripts.cmake")
        list(APPEND paths_DELETED "cmake/scripts/__dk-find-scripts.cmake")
      endif()
      unset(delete)
    endif()
    
    # Do Git operations automatically
    if(IS_DIRECTORY "${dest}/.git")
      find_package(Git QUIET REQUIRED)

      # install .gitattributes
      if(NOT EXISTS "${dest}/${path_gitattributes}")
        file(INSTALL "${file_gitattributes}"
          DESTINATION "${dest}"
          FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
        list(APPEND paths_ADDED "${path_gitattributes}")
      endif()

      # add the four files
      execute_process(WORKING_DIRECTORY "${dest}"
        COMMAND "${GIT_EXECUTABLE}" add ${paths_ADDED}
        COMMAND_ERROR_IS_FATAL ANY)
      
      # deletions
      if(paths_DELETED)
          execute_process(WORKING_DIRECTORY "${dest}"
            COMMAND "${GIT_EXECUTABLE}" rm -f ${paths_DELETED}
            COMMAND_ERROR_IS_FATAL ANY)
      endif()

      # for Windows, the *_EXECUTE permissions earlier do nothing. And a subsequent `git add` will not set the
      # git chmod +x bit. So we force it.
      execute_process(WORKING_DIRECTORY "${dest}"
        COMMAND "${GIT_EXECUTABLE}" update-index --chmod=+x "${path_dk}"
        COMMAND_ERROR_IS_FATAL ANY)
    endif()

    # Prompt next steps for HERE users
    if(ARG_HERE)
      set(invocation ./dk)
      if(WIN32)
        set(invocation [[.\dk]])
      endif()
      message(NOTICE "
The final installation step is to run:

  ${invocation} dkml.wrapper.upgrade DONE
")
    endif()
endfunction()
