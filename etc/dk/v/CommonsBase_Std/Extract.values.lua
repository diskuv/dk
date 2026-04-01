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
    local paths = assert(request.user.paths, "please provide `'paths[]=PATH1' 'paths[]=PATH2' ...`")
    assert(type(paths) == "table", "paths must be a table. please provide `'paths[]=PATH1' 'paths[]=PATH2' ...`")
    local p = {
      paths = paths
    }
    CommonsBase_Std__Extract__0_1_0.common_params(request, p)
    if request.execution.OSFamily == "macos" then
      return CommonsBase_Std__Extract__0_1_0.untar_macos(p)
    elseif request.execution.OSFamily == "linux" then
      return CommonsBase_Std__Extract__0_1_0.untar_linux(p)
    elseif request.execution.OSFamily == "windows" then
      if p.gzip or p.xz or p.bz2 then
        return CommonsBase_Std__Extract__0_1_0.untarsomez_win32(p)
      else
        return CommonsBase_Std__Extract__0_1_0.untar_win32(p)
      end
    else
      error("unsupported OSFamily: " .. request.execution.OSFamily)
    end
  end
end

function rules.F_TarToZip(command, request)
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
    local p = {}
    CommonsBase_Std__Extract__0_1_0.common_params(request, p)
    if request.execution.OSFamily == "macos" then
      return CommonsBase_Std__Extract__0_1_0.tartozip_macos(p)
    elseif request.execution.OSFamily == "linux" then
      return CommonsBase_Std__Extract__0_1_0.tartozip_linux(p)
    elseif request.execution.OSFamily == "windows" then
      if p.gzip or p.xz or p.bz2 then
        return CommonsBase_Std__Extract__0_1_0.tartozip_somez_win32(p)
      else
        return CommonsBase_Std__Extract__0_1_0.tartozip_win32(p)
      end
    else
      error("unsupported OSFamily: " .. request.execution.OSFamily)
    end
  end
end

function CommonsBase_Std__Extract__0_1_0.common_params(request, p)
  local tarmodver = assert(request.user.tarmodver, "please provide `tarmodver=MODULE@VERSION`")
  local tarassetpath = assert(request.user.tarassetpath, "please provide `tarassetpath=ASSETPATH`")
  local gzip = string.find(tarassetpath, "%.tar%.gz$") ~= nil
  local xz = string.find(tarassetpath, "%.tar%.xz$") ~= nil
  local bz2 = string.find(tarassetpath, "%.tar%.bz2$") ~= nil
  local toyboxexe = string.format(
    "$(get-object CommonsBase_Std.Toybox@0.8.9 -s Release.%s -m ./toybox -f toybox.exe -e '*')",
    request.execution.ABIv3)
  local sevenzzexe = string.format(
    "$(get-object CommonsBase_Std.S7z@25.1.0 -s Release.%s -m ./7zz.exe -f 7zz.exe -e '*')",
    request.execution.ABIv3)
  local sevenzexe_win32 = string.format(
    "$(get-object CommonsBase_Std.S7z.Windows7zExe@25.1.0 -s Release.%s -d :)/7z.exe",
    request.execution.ABIv3)
  local coreutilsexe = string.format(
    "$(get-object CommonsBase_Std.Coreutils@0.2.2 -s Release.%s -m ./coreutils.exe -f coreutils.exe -e '*')",
    request.execution.ABIv3)

  -- /a/b/c.tar.gz -> ("z", /a/b/c.tar)
  -- /a/b/c.tar.xz -> ("J", /a/b/c.tar)
  -- /a/b/c.tar.bz2 -> ("j", /a/b/c.tar)
  local tarcompressflag = ""
  local file_tar = ""
  if gzip then
    tarcompressflag = "z"
    file_tar = string.sub(tarassetpath, 1, -4) -- remove .gz
  elseif xz then
    tarcompressflag = "J"
    file_tar = string.sub(tarassetpath, 1, -4) -- remove .xz
  elseif bz2 then
    tarcompressflag = "j"
    file_tar = string.sub(tarassetpath, 1, -5) -- remove .bz2
  else
    file_tar = tarassetpath
  end

  -- file_tar=/a/b/c.tar        -> c.tar
  -- tarassetpath=/a/b/c.tar.gz -> c.tar.gz
  local baseidx = assert(string.find(file_tar, "[^/][^/]*$"), "`" .. tarassetpath .. "` tarball must have a basename")
  local file_tar_basename = string.sub(file_tar, baseidx)
  local file_tarz_filename = string.sub(tarassetpath, baseidx)

  p.outputid = request.submit.outputid
  p.outputmodule = request.submit.outputmodule
  p.outputversion = request.submit.outputversion

  p.tarfile = string.format("$(get-asset %s -p %s -f %s)", tarmodver, tarassetpath, file_tarz_filename)
  p.file_tar = file_tar
  p.file_tar_basename = file_tar_basename
  p.tarcompressflag = tarcompressflag
  p.gzip = gzip
  p.xz = xz
  p.bz2 = bz2
  p.toyboxexe = toyboxexe
  p.sevenzzexe = sevenzzexe
  p.sevenzexe_win32 = sevenzexe_win32
  p.coreutilsexe = coreutilsexe
end

function CommonsBase_Std__Extract__0_1_0.untar_macos(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "macos" } },
              commands = {
                { -- macOS system tar
                  "/usr/bin/tar",
                  "-x" .. p.tarcompressflag .. "f",
                  p.tarfile,
                  "-C",
                  "${SLOT.Release.Agnostic}" }
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

function CommonsBase_Std__Extract__0_1_0.tartozip_macos(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "macos" } },
              commands = {
                { -- macOS system tar
                  "/usr/bin/tar",
                  "-x" .. p.tarcompressflag .. "f",
                  p.tarfile
                },
                {
                  -- [p.sevenzzee] is 7zz
                  p.sevenzzexe,
                  "a",
                  "${SLOT.Release.Agnostic}/output.zip"
                }
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = { "output.zip" }
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
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "linux" } },
              commands = {
                {
                  p.toyboxexe,
                  "tar",
                  "-x" .. p.tarcompressflag .. "f",
                  p.tarfile,
                  "-C",
                  "${SLOT.Release.Agnostic}"
                } }
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

function CommonsBase_Std__Extract__0_1_0.tartozip_linux(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "linux" } },
              commands = {
                {
                  p.toyboxexe,
                  "tar",
                  "-x" .. p.tarcompressflag .. "f",
                  p.tarfile
                },
                {
                  -- [p.sevenzzee] is 7zz
                  p.sevenzzexe,
                  "a",
                  "${SLOT.Release.Agnostic}/output.zip"
                }
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = { "output.zip" }
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
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "windows" } },
              commands = {
                -- extract the .tar.gz/.tar.xz/.tar.bz2 to a .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  -- uncompress
                  "x",
                  -- to current directory
                  "-o.",
                  -- the .tar.gz
                  p.tarfile,
                  -- select the .tar extracted output
                  p.file_tar_basename
                },
                -- extract the .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  -- uncompress
                  "x",
                  -- to output directory
                  "-o${SLOT.Release.Agnostic}",
                  -- the tarball
                  p.file_tar_basename
                } }
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

function CommonsBase_Std__Extract__0_1_0.tartozip_somez_win32(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "windows" } },
              commands = {
                -- extract the .tar.gz/.tar.xz/.tar.bz2 to a .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  -- uncompress
                  "x",
                  -- to current directory
                  "-o.",
                  -- the .tar.gz
                  p.tarfile,
                  -- select the .tar extracted output
                  p.file_tar_basename
                },
                -- make temp directory
                {
                  p.coreutilsexe,
                  "mkdir",
                  "${CACHE}"
                },
                -- move the .tar to a temp directory
                {
                  p.coreutilsexe,
                  "mv",
                  p.file_tar_basename,
                  "${CACHE}/" .. p.file_tar_basename
                },
                -- extract the .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  -- uncompress
                  "x",
                  -- to current directory
                  "-o.",
                  -- the tarball
                  "${CACHE}/" .. p.file_tar_basename
                },
                -- remove the .tar from the temp directory
                {
                  p.coreutilsexe,
                  "rm",
                  "${CACHE}/" .. p.file_tar_basename
                },
                -- create output.zip from the .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  "a",
                  "${SLOT.Release.Agnostic}/output.zip"
                }
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = { "output.zip" }
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
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "windows" } },
              commands = {
                -- with [7z.exe] ...
                p.sevenzexe_win32,
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

function CommonsBase_Std__Extract__0_1_0.tartozip_win32(p)
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          {
            id = p.outputid,
            function_ = {
              execution = { { name = "OSFamily", value = "windows" } },
              commands = {
                -- extract the .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  -- uncompress
                  "x",
                  -- to current directory
                  "-o.",
                  -- the tarball
                  p.tarfile
                },
                -- create output.zip from the .tar
                {
                  -- with [7z.exe] ...
                  p.sevenzexe_win32,
                  "a",
                  "${SLOT.Release.Agnostic}/output.zip"
                }
              }
            },
            outputs = {
              assets = {
                {
                  slots = { "Release.Agnostic" },
                  paths = { "output.zip" }
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
