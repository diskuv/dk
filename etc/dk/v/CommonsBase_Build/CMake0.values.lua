-- USAGE 1 OF 2: CommonsBase_Build.CMake0.F_Build@3.25.3 (bundlemodver= | assetmodver= assetpath=)
-- (Free rule) Generates a CMake build directory, builds the CMake project and installs the CMake project in the output directory.
-- Either bundlemodver or assetmodver+assetpath must be provided.
-- Options:
--  generator: the cmake generator to use (defaults to "Ninja")
--  assetmodver: asset module@version of CMake source directory
--  assetpath: path inside the asset module to the CMake source directory
--  bundlemodver: bundle module@version of CMake source directory
--  sourcesubdir: subdirectory inside the asset or bundle that contains the CMakeLists.txt (defaults to root of asset or bundle)
--  gargs[]: list of cmake generator arguments to pass to cmake executable.
--        The -S source directory is required.
--        The -B build directory will already be set.
--  bargs[]: list of cmake build arguments to pass to cmake executable.
--  iargs[]: list of cmake install arguments to pass to cmake executable.
--  out[]: list of expected output files in the build directory
--  exe[]: list of glob patterns for executables to set execute permissions (Unix) and locally codesign (macOS).
-- example:
--  dk0 post-object CommonsBase_Build.CMake0.F_Build@3.25.3 generator=Ninja 'iargs[]=-S' 'iargs[]=.' 'out[]=bin/cmake-generated.exe'

-- USAGE 2 OF 2: CommonsBase_Build.CMake0.Generate@3.25.3
-- (UI rule) Generates a CMake build system in the build directory.
-- All options of F_Build except bundlemodver/assetmodver/assetpath are supported,
-- but installdir= is required.
-- Options:
--  installdir: the install directory to pass to `cmake --install ... --prefix INSTALL_DIRECTORY`

-- Why a rule instead of a simpler `get-object`?
-- Because dk0 objects are deterministic zip files that do not allow symlinks.
-- Symlinks cause inconsistency across platforms so with deterministic objects
-- the CMake.app code signature output by `get-object` would be invalid on macOS.

local M = {
  id = "CommonsBase_Build.CMake0@3.25.3"
}

-- lua-ml does not support local functions.
-- And if the variable was "local" it would be nil inside rules.Untar.
-- So a should-be-unique global is used instead.
CommonsBase_Build__CMake0__3_25_3 = {}

rules, uirules = build.newrules(M)

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
    local generator = request.user.generator or "Ninja"
    local bundlemodver = request.user.bundlemodver
    local assetmodver = request.user.assetmodver
    local assetpath = request.user.assetpath
    assert(bundlemodver or assetmodver,
      "please provide either 'bundlemodver=BUNDLEMODULE@VERSION' or 'assetmodver=ASSETMODULE@VERSION' for the CMake source directory")
    if assetmodver then
      assert(assetpath, "please provide 'assetpath=PATH_INSIDE_ASSET' when using 'assetmodver=ASSETMODULE@VERSION'")
    end

    -- SYNC: rules.F_Build#A, uirules.Build#A
    local gargs = request.user.gargs or {}
    local bargs = request.user.bargs or {}
    local iargs = request.user.iargs or {}
    local sourcesubdir = assert(string.sanitizesubdir(request.user.sourcesubdir or "."))
    local out = request.user.out
    assert(type(out) == "table", "out must be a table. please provide `'out[]=FILE1' 'out[]=FILE2' ...`")
    local exe = request.user.exe or {}

    local p = {
      outputid = request.submit.outputid,
      abi = request.execution.ABIv3,
      generator = generator,
      bundlemodver = bundlemodver,
      assetmodver = assetmodver,
      assetpath = assetpath,
      sourcesubdir = sourcesubdir,
      gargs = gargs,
      bargs = bargs,
      iargs = iargs,
      out = out,
      exe = exe
    }

    -- print args
    -- print("CommonsBase_Build.CMake0.Generate@3.25.3 has the user object:")
    -- local json = require("buildjson")
    -- print(json.encode(request.user, { indent = 1 }))


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
      p.osfamily = "windows"
      return CommonsBase_Build__CMake0__3_25_3.free_generate_build_install(request, p)
    else
      error("unsupported OSFamily: " .. request.execution.OSFamily)
    end
  end
end

function uirules.Build(command, request)
  local installdir = assert(request.user.installdir, "please provide 'installdir=INSTALL_DIRECTORY'")
  local generator = request.user.generator or "Ninja"

  local srcglobs = request.user.src
  assert(type(srcglobs) == "table",
    "src must be a table. please provide 'src[]=GLOB1' 'src[]=GLOB2' ...")

  -- SYNC: rules.F_Build#A, uirules.Build#A
  local gargs = request.user.gargs or {}
  local bargs = request.user.bargs or {}
  local iargs = request.user.iargs or {}
  local sourcesubdir = assert(string.sanitizesubdir(request.user.sourcesubdir or "."))
  local out = request.user.out
  assert(type(out) == "table", "out must be a table. please provide `'out[]=FILE1' 'out[]=FILE2' ...`")
  local exe = request.user.exe or {}

  local outputid = "OurCMake_Build." .. request.rule.generatesymbol() .. "@1.0.0"
  local p = {
    outputid = outputid,
    abi = request.execution.ABIv3,
    generator = generator,
    gargs = gargs,
    bargs = bargs,
    iargs = iargs,
    sourcesubdir = sourcesubdir,
    srcglobs = srcglobs,
    out = out,
    installdir = installdir,
    exe = exe
  }

  -- print args
  -- print("CommonsBase_Build.CMake0.Generate@3.25.3 has the user object:")
  -- local json = require("buildjson")
  -- print(json.encode(request.user, { indent = 1 }))

  return CommonsBase_Build__CMake0__3_25_3.ui_generate_build_install(command, request, p)
end

function CommonsBase_Build__CMake0__3_25_3.free_generate_build_install(request, p)
  -- the source directory will be "s/" inside the function directory
  -- the build directory will be "b/" inside the function directory
  local sourcedir
  if p.sourcesubdir == "." or p.sourcesubdir == "./" then
    sourcedir = "s"
  else
    sourcedir = quote.value_shell("s/" .. p.sourcesubdir)
  end

  -- precommand to get source
  local precommand_getsource
  if p.bundlemodver then
    precommand_getsource = "get-bundle " .. p.bundlemodver .. " -d s"
  else
    precommand_getsource = "get-asset " .. p.assetmodver .. " -p " .. p.assetpath .. " -d s"
  end

  -- concatenate p.gargs into string "generate_cmd"
  local gargs = {
    p.cmakeexe, "-G", p.generator, "-S", sourcedir, "-B", "b"
  }
  table.move(p.gargs, 1, table.getn(p.gargs), table.getn(gargs) + 1, gargs) ---@diagnostic disable-line: deprecated, access-invisible

  -- concatenate p.bargs into string "build_cmd"
  local bargs = {
    p.cmakeexe, "--build", "b"
  }
  table.move(p.bargs, 1, table.getn(p.bargs), table.getn(bargs) + 1, bargs) ---@diagnostic disable-line: deprecated, access-invisible

  -- concatenate p.iargs into array "iargs"
  local iargs = {
    p.cmakeexe, "--install", "b", "--prefix", "${SLOT.Release.Agnostic}"
  }
  table.move(p.iargs, 1, table.getn(p.iargs), table.getn(iargs) + 1, iargs) ---@diagnostic disable-line: deprecated, access-invisible

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
              args = {
                gargs,
                bargs,
                iargs
              }
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

function CommonsBase_Build__CMake0__3_25_3.ui_generate_build_install(command, request, p)
  local k, v, a
  if command == "submit" then
    local bundle, getbundle, getasset = request.ui.glob {
      patterns = p.srcglobs, cell = "root"
    }

    -- bundlemodver
    local bundlemodver = assert(bundle.id, "could not determine bundle module version from src globs")

    -- out
    local arg_out = {}
    k, v = next(p.out)
    while k do
      a = "out[]=" .. v -- "out[]=FILE" is F_Build option
      arg_out[k] = a
      k, v = next(p.out, k)
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

    -- concatenate [arg_out] and [arg_exe] into command
    local command = { "post-object", "CommonsBase_Build.CMake0.F_Build@3.25.3",
      "-d", p.installdir,
      "bundlemodver=" .. bundlemodver,
      "sourcesubdir=" .. p.sourcesubdir
    }
    table.move(arg_out, 1, table.getn(arg_out), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_exe, 1, table.getn(arg_exe), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_gargs, 1, table.getn(arg_gargs), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_bargs, 1, table.getn(arg_bargs), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(arg_iargs, 1, table.getn(arg_iargs), table.getn(command) + 1, command) ---@diagnostic disable-line: deprecated, access-invisible

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

return M
