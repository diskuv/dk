-- usage: CommonsBase_Std.Extract.Untar@0.1.0 tarfile= modver= paths[]=
--
--  tarfile=$PWD/target/nothing.tar.gz
--    The tar or tar.gz file to extract.
--  modver=OurTest_Std.Extract@0.1.0
--    The MODULE@VERSION of the form object that will contain the extracted files.
--    The slot for the form object will be `Release.Agnostic`.
--  paths[]=README.md
--    All of the extracted paths.
--    A future version may extract only the specified paths,
--    but for now we extract all files and expect you to declare them all.
--
-- On macOS the /usr/bin/tar system binary is used.
-- On Linux the toybox tar command is fetched from an asset and used.
-- On Windows the 7z.exe command is fetched from an asset and used.
--
-- testing:
--   tar cvf target/nothing.tar README.md
--   _build/default/ext/MlFront/src/MlFront_Exec/Shell.exe --trial -isystem ./ext/dk/etc/dk/i -I ext/dk/etc/dk/v --trust-local-package CommonsBase_Std post-object CommonsBase_Std.Extract.Untar@0.1.0 -f target/untar modver=OurTest_Std.Extract@0.1.0 tarfile=$PWD/target/nothing.tar 'paths[]=README.md'

local M = {
  id = "CommonsBase_Std.Extract@0.1.0"
}
-- lua-ml does not support local functions.
-- And if the variable was "local" it would be nil inside rules.Untar.
-- So a should-be-unique global is used instead.
CommonsBase_Std__Extract__0_1_0 = {}

rules = build.newrules(M)

function CommonsBase_Std__Extract__0_1_0.untar_macos(p)
  local compressflag = ""
  if p.gzip then
    compressflag = "z"
  end
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "macos" } },
              args = {
                -- macOS system tar
                "/usr/bin/tar",
                "-x" .. compressflag .. "f",
                p.tarfile,
                "-C",
                "${SLOT.Release.Agnostic}"
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = p.paths
                }
              }
            }
          }
        }
      }
    }
  }
end

function CommonsBase_Std__Extract__0_1_0.untar_linux(p)
  local toyboxexe = string.format(
    "$(get-object CommonsBase_Std.Toybox@0.8.9 -s Release.%s -m ./toybox -f :exe)", p.abi)
  local compressflag = ""
  if p.gzip then
    compressflag = "z"
  end
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "linux" } },
              args = {
                toyboxexe,
                "tar",
                "-x" .. compressflag .. "f",
                p.tarfile,
                "-C",
                "${SLOT.Release.Agnostic}"
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = p.paths
                }
              }
            }
          },
          {
            id = "CommonsBase_Std.Toybox@0.8.9",
            precommands = {
              private = {
                "get-asset CommonsBase_Std.Toybox@0.8.9 -p toybox-x86_64 -f ${SLOT.Release.Linux_x86_64}/toybox",
                "get-asset CommonsBase_Std.Toybox@0.8.9 -p toybox-aarch64 -f ${SLOT.Release.Linux_arm64}/toybox",
                "get-asset CommonsBase_Std.Toybox@0.8.9 -p toybox-i686 -f ${SLOT.Release.Linux_x86}/toybox"
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Linux_arm64", "Release.Linux_x86", "Release.Linux_x86_64" },
                  paths = { "toybox" }
                }
              }
            }
          }
        }
      }
    }
  }
end

function CommonsBase_Std__Extract__0_1_0.untar_win32(p)
  local sevenzexe = string.format(
    "$(get-object CommonsBase_Std.S7z.Windows7zExe@25.1.0 -s Release.%s -d :)/7z.exe", p.abi)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "windows" } },
              args = {
                -- with [7z.exe] ...
                sevenzexe,
                -- uncompress
                "x",
                -- to output directory
                "-o${SLOT.Release.Agnostic}"
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = p.paths
                }
              }
            }
          }
        }
      }
    }
  }
end

function rules.Untar(command, request)
  if command == "declareoutput" then
    local modver = assert(request.user.modver, "please provide `modver=MODULE@VERSION`")
    return {
      declareoutput = {
        return_form = {
          id = modver,
          slot = "Release.Agnostic"
        }
      }
    }
  elseif command == "submit" then
    local tarfile = assert(request.user.tarfile, "please provide `'tarfile=SOURCE'`")
    local paths = assert(request.user.paths, "please provide `'paths[]=PATH1' 'paths[]=PATH2' ...`")
    assert(type(paths) == "table", "paths must be a table. please provide `'paths[]=PATH1' 'paths[]=PATH2' ...`")
    local gzip = string.find(tarfile, "%.tar%.gz$") ~= nil
    local p = {
      outputid = request.submit.outputid,
      tarfile = tarfile,
      paths = paths,
      abi = request.execution.ABIv3,
      gzip = gzip
    }
    if request.execution.OSFamily == "macos" then
      return CommonsBase_Std__Extract__0_1_0.untar_macos(p)
    elseif request.execution.OSFamily == "linux" then
      return CommonsBase_Std__Extract__0_1_0.untar_linux(p)
    elseif request.execution.OSFamily == "windows" then
      return CommonsBase_Std__Extract__0_1_0.untar_win32(p)
    else
      error("unsupported OSFamily: " .. request.execution.OSFamily)
    end
  end
end

return M
