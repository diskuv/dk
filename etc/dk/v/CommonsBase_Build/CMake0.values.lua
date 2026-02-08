-- USAGE 1 OF 2: CommonsBase_Build.CMake0.Build@3.25.3
-- (UI rule) Generates a CMake build system in the build directory.
-- Configurations: One of the following sets of options must be provided:
--   installdir= src[]=
--   installdir= mirrors[]= urlpath=
-- Options:
--  src[]: list of glob patterns for the local source directory
--  mirrors[]: HTTP base urls to download the CMake source directory
--  urlpath: path added to the mirrors so full URL is a ZIP file of the CMake source directory
--  installdir: (required) the install directory to pass to `cmake --install ... --prefix INSTALL_DIRECTORY`
--  generator: the cmake generator to use (defaults to "Ninja")
--  sourcesubdir: subdirectory inside the asset or bundle that contains the CMakeLists.txt (defaults to root of asset or bundle)
--  nstrip: levels of leading directories to nstrip while extract asset or bundle (defaults to 0)
--  gargs[]: list of cmake generator arguments to pass to cmake executable.
--        The -S source directory is required.
--        The -B build directory will already be set.
--  bargs[]: list of cmake build arguments to pass to cmake executable.
--  iargs[]: list of cmake install arguments to pass to cmake executable.
--  out[]: (required) list of expected output files in the build directory
--  outrmexact[]: list of exact strictly relative paths (relative to build directory) to remove
--  outrmglob[]: list of "fd" filename glob patterns for files in the build directory to remove after outrmexact[]
--  exe[]: list of glob patterns for executables to set execute permissions (Unix) and locally codesign (macOS).
-- examples:
--  dk0 --trial run CommonsBase_Build.CMake0.Build@3.25.3 \
--    installdir=t/i \
--    'mirrors[]=https://github.com/google/or-tools/archive/refs/tags' \
--    'urlpath=v9.15.zip#920d8266b30a7a8f8572a5dc663fdf8d2701792101dd95f09e72397c16e12858,25297362' \
--    'nstrip=1' \
--    'gargs[]=-DBUILD_DEPS:BOOL=ON' \
--    'out[]=bin/nqueue_sat'
-- what gets run: (see usage for "CommonsBase_Build.CMake0.F_Build@3.25.3" below)

-- USAGE 2 OF 2: CommonsBase_Build.CMake0.F_Build@3.25.3
-- (Free rule) Generates a CMake build directory, builds the CMake project and installs the CMake project in the output directory.
-- Configurations: One of the following sets of options must be provided:
--  bundlemodver=
--  assetmodver= assetpath=
-- Options:
--  generator: the cmake generator to use (defaults to "Ninja")
--  assetmodver: asset module@version of CMake source directory
--  assetpath: path inside the asset module to the CMake source directory
--  bundlemodver: bundle module@version of CMake source directory
--  sourcesubdir: subdirectory inside the asset or bundle that contains the CMakeLists.txt (defaults to root of asset or bundle)
--  nstrip: levels of leading directories to nstrip while extract asset or bundle (defaults to 0)
--  gargs[]: list of cmake generator arguments to pass to cmake executable.
--        The -S source directory is required.
--        The -B build directory will already be set.
--  bargs[]: list of cmake build arguments to pass to cmake executable.
--  iargs[]: list of cmake install arguments to pass to cmake executable.
--  out[]: (required) list of expected output files in the build directory
--  outrmexact[]: list of exact strictly relative paths (relative to build directory) to remove
--  outrmglob[]: list of "fd" filename glob patterns for files in the build directory to remove after outrmexact[]
--  exe[]: list of glob patterns for executables to set execute permissions (Unix) and locally codesign (macOS).
-- examples:
--  dk0 --trial post-object CommonsBase_Build.CMake0.F_Build@3.25.3 \
--    generator=Ninja 'iargs[]=-S' 'iargs[]=.' 'out[]=bin/cmake-generated.exe'
-- what gets run:
--   get-asset <assetmodver> -p <assetpath> -d s [-or-] get-bundle <bundlemodver> -d s
--   $(get-object CommonsBase_Build.Ninja0@1.12.1 -s Release.<execution abi> -m ./ninja.exe -f : -e '*') (if generator is "Ninja")
--   cmake -G <generator> -S s/<sourcesubdir> -B b
--     -DCMAKE_INSTALL_PREFIX:FILEPATH=${SLOTABS.Release.Agnostic}
--     -DCMAKE_MAKE_PROGRAM:FILEPATH=<path to ninja.exe> (if generator is "Ninja")
--     <gargs>
--   cmake --build b <bargs>
--   cmake --install b --prefix ${SLOTABS.Release.Agnostic} <iargs>

-- COMPILERS
--
-- ::: Windows / Visual Studio
-- <TODO> The Ninja generator (the default) only works on Windows when the build is run in a Visual Studio Developer Command Prompt.

-- DESIGN QUESTIONS
-- Q1: Why a rule instead of a simpler `get-object`?
-- ANS1: Because dk0 objects are deterministic zip files that do not allow symlinks.
-- Symlinks cause inconsistency across platforms so with deterministic objects
-- the CMake.app code signature output by `get-object` would be invalid on macOS.
--
-- Q2: CMAKE_INSTALL_PREFIX?
-- The CMAKE_INSTALL_PREFIX is set for CMake projects like google/or-tools that do not respect
-- the prefix option in `cmake --install --prefix` (usually when the project sets CMAKE_INSTALL_PREFIX CACHE
-- variable by default).
--
-- Q3: Hermeticity?
-- In a <FUTURE> version, CMakeCache.txt can be checked in this rule to find out if all the CACHE variables are hermetic.
--    Example: BAD: _Python3_EXECUTABLE:INTERNAL=/opt/homebrew/Frameworks/Python.framework/Versions/3.11/bin/python3.11
--    Example: GOOD: generated_dir:INTERNAL=/Volumes/SSD/Source/dk/t/p/4472/e7lu/f/Release.Agnostic/b/_deps/googletest-build/googletest/generated


local M = {
  id = "CommonsBase_Build.CMake0@3.25.3"
}

-- lua-ml does not support local functions.
-- And if the variable was "local" it would be nil inside the rules/uirules function bodies.
-- So a should-be-unique global is used instead.
CommonsBase_Build__CMake0__3_25_3 = {}

rules, uirules = build.newrules(M)

function CommonsBase_Build__CMake0__3_25_3.parse_common_args(request, p)
  p.execabi = request.execution.ABIv3
  p.gargs = request.user.gargs or {}
  p.bargs = request.user.bargs or {}
  p.iargs = request.user.iargs or {}
  p.sourcesubdir = assert(stringdk.sanitizesubpath(request.user.sourcesubdir or "."))
  p.out = request.user.out
  assert(type(p.out) == "table", "out must be a table. please provide `'out[]=FILE1' 'out[]=FILE2' ...`")
  p.outrmexact = request.user.outrmexact or {}
  p.outrmglob = request.user.outrmglob or {}
  p.exe = request.user.exe or {}
  p.nstrip = request.user.nstrip or 0
end

function uirules.Build(command, request)
  local installdir = assert(request.user.installdir, "please provide 'installdir=INSTALL_DIRECTORY'")
  local generator = request.user.generator or "Ninja"

  local src = request.user.src
  local mirrors = request.user.mirrors
  local urlpath = request.user.urlpath
  if src then
    assert(type(src) == "table",
      "src must be a table. please provide 'src[]=GLOB1' 'src[]=GLOB2' ...")
  else
    assert(mirrors and urlpath,
      "please provide either 'src[]=GLOB_PATTERN' or both 'mirrors[]=MIRROR_URL' and 'urlpath=URL_PATH'")
    assert(type(mirrors) == "table",
      "mirrors must be a table. please provide 'mirrors[]=MIRROR1' 'mirrors[]=MIRROR2' ...")

    -- validate mirrors are https:// or http://
    local k, v = next(mirrors)
    while k do
      local s, e = string.find(v, "^https?://")
      assert(s == 1, "mirror `" .. v .. "` must start with 'http://' or 'https://'")
      k, v = next(mirrors, k)
    end
  end

  -- parse arguments
  local p = {}
  CommonsBase_Build__CMake0__3_25_3.parse_common_args(request, p)

  -- split urlpath=path#sha256,size
  local urlpath_only, urlpath_sha256, urlpath_size
  if urlpath then
    local s1, e1 = string.find(urlpath, "#")
    assert(s1 and e1, "urlpath `" .. urlpath .. "` must be in the format path#sha256,size")
    urlpath_only = string.sub(urlpath, 1, s1 - 1)
    local s2, e2 = string.find(urlpath, ",", e1 + 1)
    assert(s2 and e2, "urlpath `" .. urlpath .. "` must be in the format path#sha256,size")
    urlpath_sha256 = string.sub(urlpath, e1 + 1, s2 - 1)
    urlpath_size = tonumber(string.sub(urlpath, e2 + 1))
  end

  p.outputid = "OurCMake_Build." .. request.rule.generatesymbol() .. "@1.0.0"
  p.generator = generator
  p.src = src
  p.mirrors = mirrors
  p.urlpath_only = urlpath_only
  p.urlpath_sha256 = urlpath_sha256
  p.urlpath_size = urlpath_size
  p.installdir = installdir

  -- delegate to helper function since this is getting large
  return CommonsBase_Build__CMake0__3_25_3.ui_generate_build_install(command, request, p)
end

function CommonsBase_Build__CMake0__3_25_3.ui_generate_build_install(command, request, p)
  local k, v, a
  if command == "submit" then
    local bundle

    -- bundlemodver or assetmodver+assetpath
    local arg_content
    if p.src then
      -- source from local files; glob it and let .F_Build extract the bundle
      bundle = request.ui.glob {
        patterns = p.src, cell = "root"
      }
      local bundlemodver = assert(bundle.id, "could not determine bundle module version from src globs")
      arg_content = { "bundlemodver=" .. bundlemodver }
    else
      -- source from remote zipfile; create an asset bundle and let .F_Build extract the zipfile asset
      local genid = request.rule.generatesymbol()
      local origin = genid .. "-content"

      bundle = {
        id = "OurCMake_UI.Content." .. genid .. "@1.0.0",
        listing = {
          origins = {
            {
              name = origin,
              mirrors = p.mirrors
            }
          }
        },
        assets = {
          {
            origin = origin,
            path = p.urlpath_only,
            size = p.urlpath_size,
            checksum = {
              sha256 = p.urlpath_sha256
            }
          }
        }
      }
      arg_content = {
        "assetmodver=" .. bundle.id,
        "assetpath=" .. p.urlpath_only
      }
    end

    -- out
    local arg_out = {}
    k, v = next(p.out)
    while k do
      a = "out[]=" .. v -- "out[]=FILE" is F_Build option
      arg_out[k] = a
      k, v = next(p.out, k)
    end

    -- outrmexact
    local arg_outrmexact = {}
    k, v = next(p.outrmexact)
    while k do
      a = "outrmexact[]=" .. v -- "outrmexact[]=GLOB_PATTERN" is F_Build option
      arg_outrmexact[k] = a
      k, v = next(p.outrmexact, k)
    end

    -- outrmglob
    local arg_outrmglob = {}
    k, v = next(p.outrmglob)
    while k do
      a = "outrmglob[]=" .. v -- "outrmglob[]=GLOB_PATTERN" is F_Build option
      arg_outrmglob[k] = a
      k, v = next(p.outrmglob, k)
    end

    -- exe
    local arg_exe = {}
    k, v = next(p.exe)
    while k do
      a = "-e" .. v -- "-e GLOB_PATTERN" is `post-object` option
      arg_exe[k] = a
      k, v = next(p.exe, k)
    end

    -- gargs
    local arg_gargs = {}
    k, v = next(p.gargs)
    while k do
      a = "gargs[]=" .. v -- "gargs[]=ARG" is F_Build option
      arg_gargs[k] = a
      k, v = next(p.gargs, k)
    end

    -- bargs
    local arg_bargs = {}
    k, v = next(p.bargs)
    while k do
      a = "bargs[]=" .. v -- "bargs[]=ARG" is F_Build option
      arg_bargs[k] = a
      k, v = next(p.bargs, k)
    end

    -- iargs
    local arg_iargs = {}
    k, v = next(p.iargs)
    while k do
      a = "iargs[]=" .. v -- "iargs[]=ARG" is F_Build option
      arg_iargs[k] = a
      k, v = next(p.iargs, k)
    end

    -- nstrip
    local arg_nstrip = {}
    if p.nstrip and p.nstrip > 0 then
      arg_nstrip = { "nstrip=" .. tostring(p.nstrip) } -- "nstrip=LEVELS" is F_Build option
    end

    -- concatenate [arg_out] and [arg_exe] into command
    local command = { "post-object", "CommonsBase_Build.CMake0.F_Build@3.25.3",
      "-d", p.installdir,
      "sourcesubdir=" .. p.sourcesubdir
    }
    table.move(arg_content, 1, table.getn(arg_content), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_out, 1, table.getn(arg_out), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_outrmexact, 1, table.getn(arg_outrmexact), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_outrmglob, 1, table.getn(arg_outrmglob), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_exe, 1, table.getn(arg_exe), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_gargs, 1, table.getn(arg_gargs), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_bargs, 1, table.getn(arg_bargs), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_iargs, 1, table.getn(arg_iargs), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_nstrip, 1, table.getn(arg_nstrip), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible

    -- print("Submitting command: " .. table.concat(command, " "))

    return {
      submit = {
        values = {
          schema_version = { major = 1, minor = 0 },
          bundles = { bundle }
        },
        commands = { command }
      }
    }
  elseif command == "ui" then
    print("done cmake build.")
  end
end

function rules.F_Build(command, request)
  if command == "declareoutput" then
    return {
      declareoutput = {
        return_form = {
          id = "OurCMake_F_Build." .. request.rule.generatesymbol() .. "@1.0.0",
          slot = "Release.Agnostic"
        }
      }
    }
  elseif command == "submit" then
    -- parse arguments
    local p = {}
    CommonsBase_Build__CMake0__3_25_3.parse_common_args(request, p)

    p.outputid = request.submit.outputid
    p.generator = request.user.generator or "Ninja"
    p.bundlemodver = request.user.bundlemodver
    p.assetmodver = request.user.assetmodver
    p.assetpath = request.user.assetpath
    assert(p.bundlemodver or p.assetmodver,
      "please provide either 'bundlemodver=BUNDLEMODULE@VERSION' or 'assetmodver=ASSETMODULE@VERSION' for the CMake source directory")
    if p.assetmodver then
      assert(p.assetpath, "please provide 'assetpath=PATH_INSIDE_ASSET' when using 'assetmodver=ASSETMODULE@VERSION'")
    end

    p.coreutilsexe = "$(get-object CommonsBase_Std.Coreutils@0.2.2 -s Release." ..
        p.execabi .. " -m ./coreutils.exe -e '*' -f coreutils.exe)"
    p.fdexe = "$(get-object CommonsBase_Std.Fd@10.3.0 -s Release." ..
        p.execabi .. " -m ./fd.exe -e '*' -f fd.exe)"

    -- ninjaexe must be absolute path since it is passed to CMAKE_MAKE_PROGRAM CACHE variable
    p.absninjaexe = "$(--path=absnative get-object CommonsBase_Build.Ninja0@1.12.1 -s Release." ..
        p.execabi ..
        " -m ./ninja.exe -f ninja -e '*')"

    if request.execution.OSFamily == "macos" then
      p.cmakeexe =
      "$(get-asset CommonsBase_Build.CMake0.Bundle@3.25.3 -p cmake-darwin_universal.zip -n 1 -d : -e 'CMake.app/Contents/bin/*')/CMake.app/Contents/bin/cmake"
      p.osfamily = "macos"
      return CommonsBase_Build__CMake0__3_25_3.free_generate_build_install(request, p)
    elseif request.execution.OSFamily == "linux" then
      local cmakeabi
      if request.execution.ABIv3 == "linux_x86_64" then
        cmakeabi = "linux_x86_64"
      elseif request.execution.ABIv3 == "linux_x86" then
        cmakeabi = "linux_x86"
      elseif request.execution.ABIv3 == "linux_arm64" then
        cmakeabi = "linux_arm64"
      else
        error("unsupported ABIv3: " .. request.execution.ABIv3)
      end
      p.cmakeexe = "$(get-asset CommonsBase_Build.CMake0.Bundle@3.25.3 -p cmake-" ..
          cmakeabi .. ".zip -n 1 -d : -e 'bin/*')/bin/cmake"
      p.osfamily = "linux"
      return CommonsBase_Build__CMake0__3_25_3.free_generate_build_install(request, p)
    elseif request.execution.OSFamily == "windows" then
      local cmakeabi
      if request.execution.ABIv3 == "windows_x86_64" then
        cmakeabi = "windows_x86_64"
      elseif request.execution.ABIv3 == "windows_x86" then
        cmakeabi = "windows_x86"
      elseif request.execution.ABIv3 == "windows_arm64" then
        cmakeabi = "windows_arm64"
      else
        error("unsupported ABIv3: " .. request.execution.ABIv3)
      end
      p.cmakeexe =
          "$(get-asset CommonsBase_Build.CMake0.Bundle@3.25.3 -p cmake-" ..
          cmakeabi .. ".zip -n 1 -d : -e 'bin/*')/bin/cmake.exe"
      -- use ninja.exe as the executable filename so it runs on Windows
      p.absninjaexe = "$(--path=absnative get-object CommonsBase_Build.Ninja0@1.12.1 -s Release." ..
          p.execabi ..
          " -m ./ninja.exe -f ninja.exe -e '*')"
      p.osfamily = "windows"
      return CommonsBase_Build__CMake0__3_25_3.free_generate_build_install(request, p)
    else
      error("unsupported OSFamily: " .. request.execution.OSFamily)
    end
  end
end

function CommonsBase_Build__CMake0__3_25_3.free_generate_build_install(request, p)
  local k, v

  -- the source directory will be "s/" inside the function directory
  -- the build directory will be "b/" inside the function directory
  local sourcedir
  if p.sourcesubdir == "." or p.sourcesubdir == "./" then
    sourcedir = "s"
  else
    sourcedir = stringdk.quote_value_shell("s/" .. p.sourcesubdir)
  end

  -- precommand to get source
  local precommand_getsource
  if p.bundlemodver then
    precommand_getsource = "get-bundle " .. p.bundlemodver .. " -d s"
  else
    precommand_getsource = "get-asset " .. p.assetmodver .. " -p " .. p.assetpath .. " -d s"
  end
  if p.nstrip and p.nstrip > 0 then
    precommand_getsource = precommand_getsource .. " -n " .. tostring(p.nstrip)
  end

  -- ninja generator args
  local gninjaargs = {}
  if p.generator == "Ninja" then
    -- CMAKE_MAKE_PROGRAM needs to be absolute path
    gninjaargs = {
      "-DCMAKE_MAKE_PROGRAM:FILEPATH=" .. p.absninjaexe
    }
  end

  -- concatenate [p.gargs] into string "generate_cmd"
  local gargs = {
    p.cmakeexe, "-G", p.generator, "-S", sourcedir, "-B", "b",
    -- CMAKE_INSTALL_PREFIX needs to be absolute path
    "-DCMAKE_INSTALL_PREFIX:FILEPATH=${SLOTABS.Release.Agnostic}"
  }
  table.move(p.gargs, 1, table.getn(p.gargs), table.getn(gargs) + 1, gargs) ---@diagnostic disable-line: deprecated, access-invisible
  table.move(gninjaargs, 1, table.getn(gninjaargs), table.getn(gargs) + 1, gargs) ---@diagnostic disable-line: deprecated, access-invisible

  -- concatenate p.bargs into string "build_cmd"
  local bargs = {
    p.cmakeexe, "--build", "b"
  }
  table.move(p.bargs, 1, table.getn(p.bargs), table.getn(bargs) + 1, bargs) ---@diagnostic disable-line: deprecated, access-invisible

  -- concatenate p.iargs into array "iargs"
  local iargs = {
    p.cmakeexe, "--install", "b",
    -- the install prefix needs to be absolute path
    "--prefix", "${SLOTABS.Release.Agnostic}"
  }
  table.move(p.iargs, 1, table.getn(p.iargs), table.getn(iargs) + 1, iargs) ---@diagnostic disable-line: deprecated, access-invisible

  -- assemble the array of commands
  local args = {
    -- run: cmake -G
    gargs,
    -- run: cmake --build
    bargs,
    -- run: cmake --install
    iargs
  }

  -- validate and add `rm -rf DIRS` for each ${SLOT.Release.Agnostic}/DIR in p.outrmexact
  local rmdirs = {}
  k, v = next(p.outrmexact)
  while k do
    v = assert(stringdk.sanitizesubpath(v)) -- sanitize to prevent malicious input
    rmdirs[k] = "${SLOT.Release.Agnostic}/" .. v
    k, v = next(p.outrmexact, k)
  end
  if (table.getn(rmdirs) > 0) then ---@diagnostic disable-line: deprecated, access-invisible
    local rmrfcmd = { p.coreutilsexe, "rm", "-rf" }
    table.move(rmdirs, 1, table.getn(rmdirs), table.getn(rmrfcmd) + 1, rmrfcmd) ---@diagnostic disable-line: deprecated, access-invisible
    local rmrfcmd1 = { rmrfcmd } -- add one [rm -rf] command
    table.move(rmrfcmd1, 1, table.getn(rmrfcmd1), table.getn(args) + 1, args) ---@diagnostic disable-line: deprecated, access-invisible
  end

  -- add `fd --glob --hidden --no-ignore -X coreutils rm -f \; -- GLOB ${SLOT.Release.Agnostic}` for each GLOB in p.outrmglob
  -- validation? the GLOB is after `--` so dashes won't be interpreted as options.
  -- also, the GLOB is applied to filenames _under_ the -C BASEDIR.
  -- so GLOB is sanitized
  -- --base-directory? it is hidden option; confer https://github.com/sharkdp/fd/issues/475
  k, v = next(p.outrmglob)
  while k do
    local fdcmd = { p.fdexe, "--glob", "--hidden", "--no-ignore",
      "-X", p.coreutilsexe, "rm", "-f", ";",
      "--", v, "${SLOT.Release.Agnostic}" }
    local fdcmd1 = { fdcmd } -- add one [fd] command
    table.move(fdcmd1, 1, table.getn(fdcmd1), table.getn(args) + 1, args) ---@diagnostic disable-line: deprecated, access-invisible
    k, v = next(p.outrmglob, k)
  end

  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            precommands = {
              private = {
                precommand_getsource
              }
            },
            function_ = {
              execution = { { name = "OSFamily", value = p.osfamily } },
              args = args
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = p.out
                }
              }
            }
          }
        }
      }
    }
  }
end

return M
