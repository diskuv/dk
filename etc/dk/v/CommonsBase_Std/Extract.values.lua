-- USAGE 1 of 1: CommonsBase_Std.Extract.F_Untar@0.1.0
-- (Free rule) Untars a tar, tar.gz, tar.xz or tar.bz2 file.
-- Configurations: One of the following sets of options must be provided:
--  tarfile= modver= paths[]=
-- Options:
--  tarfile=$PWD/target/nothing.tar.gz
--    The tar, tar.gz, tar.xz or tar.bz2 file to extract.
--  modver=OurTest_Std.Extract@0.1.0
--    The MODULE@VERSION of the form object that will contain the extracted files.
--    The slot for the form object will be `Release.Agnostic`.
--  paths[]=README.md
--    All of the extracted paths.
--    A future version may extract only the specified paths,
--    but for now we extract all files and expect you to declare them all.

-- DESIGN QUESTIONS
-- 
-- Q1: Platforms?
-- A1: On macOS the /usr/bin/tar system binary is used.
-- On Linux the toybox tar command is fetched from an asset and used.
-- On Windows the 7z.exe command is fetched from an asset and used.
-- 
-- Q2: There is no way to filter which files I want.
-- A2: <FUTURE> This rule will be renamed to CommonsBase_Std.Extract0, and the new CommonsBase_Std.Extract
-- will run CommonsBase_Std.Fd on the extracted files to filter them. The split is because
-- CommonsBase_Std.Fd requires CommonsBase_Std.Extract0.
--
-- examples:
--   tar cvf target/nothing.tar README.md
-- 
--   dk0 --trial post-object CommonsBase_Std.Extract.F_Untar@0.1.0 \
--     -f target/untar modver=OurTest_Std.Extract@0.1.0 \
--     tarfile=$PWD/target/nothing.tar 'paths[]=README.md'
-- 
--   {or local dev}
-- 
--   _build/default/ext/MlFront/src/MlFront_Exec/Shell.exe \
--     -isystem ./ext/dk/etc/dk/i -I ext/dk/etc/dk/v \
--     --trust-local-package CommonsBase_Std \
--     --trial post-object CommonsBase_Std.Extract.F_Untar@0.1.0 \
--     -f target/untar modver=OurTest_Std.Extract@0.1.0 \
--     tarfile=$PWD/target/nothing.tar 'paths[]=README.md'

local M = {
  id = "CommonsBase_Std.Extract@0.1.0"
}

-- lua-ml does not support local functions.
-- And if the variable was "local" it would be nil inside the rules/uirules function bodies.
-- So a should-be-unique global is used instead.
CommonsBase_Std__Extract__0_1_0 = {}

rules = build.newrules(M)

function rules.F_Untar(command, request)
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
    local xz = string.find(tarfile, "%.tar%.xz$") ~= nil
    local bz2 = string.find(tarfile, "%.tar%.bz2$") ~= nil
    local p = {
      outputid = request.submit.outputid,
      outputmodule = request.submit.outputmodule,
      outputversion = request.submit.outputversion,
      tarfile = tarfile,
      paths = paths,
      abi = request.execution.ABIv3,
      gzip = gzip,
      xz = xz,
      bz2 = bz2
    }
    if request.execution.OSFamily == "macos" then
      return CommonsBase_Std__Extract__0_1_0.untar_macos(p)
    elseif request.execution.OSFamily == "linux" then
      return CommonsBase_Std__Extract__0_1_0.untar_linux(p)
    elseif request.execution.OSFamily == "windows" then
      if gzip or xz or bz2 then
        return CommonsBase_Std__Extract__0_1_0.untarsomez_win32(p)
      else
        return CommonsBase_Std__Extract__0_1_0.untar_win32(p)
      end
    else
      error("unsupported OSFamily: " .. request.execution.OSFamily)
    end
  end
end

function CommonsBase_Std__Extract__0_1_0.untar_macos(p)
  local compressflag = ""
  if p.gzip then
    compressflag = "z"
  elseif p.xz then
    compressflag = "J"
  elseif p.bz2 then
    compressflag = "j"
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
    "$(get-object CommonsBase_Std.Toybox@0.8.9 -s Release.%s -m ./toybox -f toybox.exe -e '*')", p.abi)
  local compressflag = ""
  if p.gzip then
    compressflag = "z"
  elseif p.xz then
    compressflag = "J"
  elseif p.bz2 then
    compressflag = "j"
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

-- tar.gz, tar.xz or tar.bz2
function CommonsBase_Std__Extract__0_1_0.untarsomez_win32(p)
  local sevenzexe = string.format(
    "$(get-object CommonsBase_Std.S7z.Windows7zExe@25.1.0 -s Release.%s -d :)/7z.exe", p.abi)
  local file_tarsomez = p.tarfile
  local file_tar
  if p.gzip then
    file_tar = string.sub(file_tarsomez, 1, -4)
  elseif p.xz then
    file_tar = string.sub(file_tarsomez, 1, -4)
  elseif p.bz2 then
    file_tar = string.sub(file_tarsomez, 1, -5)
  else
    error("unsupported compression format for Windows: " .. p.tarfile)
  end
  
  -- /a/b/c.tar -> c.tar
  local baseidx = assert(string.find(file_tar, "[^/][^/]*$"), "`" .. p.tarfile .. "` tarball must have a basename")
  local file_tar_basename = string.sub(file_tar, baseidx)
  local gzmodver = p.outputmodule .. ".Gz@" .. p.outputversion
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          -- extract the .tar.gz/.tar.xz/.tar.bz2 to a .tar
          {
            id = gzmodver,
            function_ = {
              execution = { { name = "OSFamily", value = "windows" } },
              args = {
                -- with [7z.exe] ...
                sevenzexe,
                -- uncompress
                "x",
                -- to output directory
                "-o${SLOT.Release.Agnostic}",
                -- the .tar.gz
                file_tarsomez,
                -- select the .tar extracted output
                file_tar_basename
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = { file_tar_basename }
                }
              }
            }
          },
          -- extract the .tar
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
                "-o${SLOT.Release.Agnostic}",
                -- the tarball
                "$(get-object " .. gzmodver .. " -s Release.Agnostic -d :)/" .. file_tar_basename
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
                "-o${SLOT.Release.Agnostic}",
                -- the tarball
                p.tarfile
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


return M
