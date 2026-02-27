-- USAGE 1 of 1: NotInriaCaml_Std.Wenv@0.1.0
-- A UI rule that creates a Windows build environment ("wenv") on Unix (currently macOS only) with a
-- native OCaml compiler using the Wine emulator.
-- The <wenv>/bin/enter script is created so you can run Windows executables like "cmd.exe".
-- 
-- SECURITY:
-- 1. You can mount arbitrary host directories in the wenv.
-- 2. The "Z:" drive in the wenv maps to the root of the host filesystem.
-- 3. The Windows (Wine) processes are not sandboxed.
-- So:
-- - Consider using https://github.com/containers/bubblewrap or similar to sandbox
--   the <wenv>/bin/enter script.
-- 
-- Configurations: One of the following sets of options must be provided:
--   dir=
-- 
-- Options:
--   dir=WENV: The absolute directory where the environment will be created.
--   mount[]=type=bind,src=<host-path>,dst=<mount-path>:
--     (optional, repeatable) Mount a host directory into the wenv.
--     For example, `mount[]=type=bind,src=/path/on/host,dst=M:\path\in\wenv` will mount the
--     host path `/path/on/host` at `M:\path\in\wenv` in the wenv.
--     [src]: Must be an absolute path on the host machine.
--     [dst]: Must be on the  M: drive which is reserved for mounted host directories.
--     It is undefined what happens when the 'dst' mount paths overlap. Don't do it!
--
-- Examples:
--   $ ./dk0 --trial run NotInriaCaml_Std.Wenv.Create@0.1.0 dir=$PWD/target/my-wenv
--   $ target/my-wenv/bin/enter cmd.exe
-- 
--   $ ./dk0 --trial run NotInriaCaml_Std.Wenv.Create@0.1.0 dir=$PWD/target/my-wenv "mount[]=type=bind,src=$PWD,dst=M:/project"
--
--   (local overrides)
--   $ ./dk0 --trial -I etc/dk/v --trust-local-package NotInriaCaml_Std --trust-local-package CommonsBase_GNU --trust-local-package CommonsBase_Win32 run NotInriaCaml_Std.Wenv.Create@0.1.0 dir=target/my-wenv
--   $ target/my-wenv/bin/enter cmd.exe
--
-- FAQ:
--
-- Q1: Why has Wine graphics been removed?
-- Currently almost all graphics features have been removed in the Wine package.
-- There might be limited support for graphics in the future, but primarily the goal is to provide a build environment.
-- Providing support for general graphics/desktop use is not sustainable for a free product!
-- Proton for Linux (https://github.com/ValveSoftware/Proton) and Crossover for Linux and macOS (https://www.codeweavers.com/crossover)
-- do Windows graphics well! Why not use them instead?
-- Advanced users: You can override the Wine package and build Wine with graphics support.
--
-- Q2: Platforms?
-- Only macOS since that is what the author (jonah@) needed while his Windows machine was rebuilt.
-- Linux, which is far better supported by Wine, should be an easy addition if someone wants to do it.
--
-- Q3: OCaml versions?
-- The OCaml version is currently hardcoded to 5.4.1.
--
-- Q4: Do the homebrew Wine packages conflict with the "wenv" environments?
-- No. They use separate Wine installations and separate Wine prefixes. The only point of contact is building a wenv ...
-- the Wenv rule will wait for all `wineserver` transient processes on the macOS machine to finish before populating the
-- wenv.
-- 
-- DESIGN NOTES:
-- 1. There is nothing special about OCaml in a wenv. It can just be a regular package added to a generic Wenv UI rule
--    command line. Then other packages (dune, alice, etc.) can also be added from the command line. Each
--    package will need some metadata.json file so the correct location in C:/opt can be determined. With rule continuations
--    the metadata.json can also have package dependencies.

local M = {
    id = "NotInriaCaml_Std.Wenv@0.1.0"
}

-- lua-ml does not support local functions.
-- And if the variable was "local" it would be nil inside the rules/uirules function bodies.
-- So a should-be-unique global is used instead.
NotInriaCaml_Std__Wenv__0_1_0 = {}

_rules, uirules = build.newrules(M)

-- TODO: dk0 should support an `ephemeral` form property so that the form is not persisted in the tracestore.
--       All of the commands manipulate the external p.wenv directory so definitely the object should not be cached!
--       Or do ephemeral automatically for any form that has no output.
function uirules.Create(command, request)
    if command == "submit" then
        local p = {}
        p.wenv = assert(request.user.dir, "Expected `dir=WENV` on the command line")
        assert(NotInriaCaml_Std__Wenv__0_1_0.validate_absolutepath("The `dir=WENV` command line argument", p.wenv))
        p.mounts = request.user.mount or {}
        p.outputid = "OurCaml_Wenv." .. request.rule.generatesymbol() .. "@1.0.0"
        p.fdexe = "$(get-object CommonsBase_Std.Fd@10.3.0 -s Release.execution_abi -m ./fd.exe -e '*' -f fd.exe)"
        p.coreutilsexe = "$(get-object CommonsBase_Std.Coreutils@0.2.2 -s Release.execution_abi -m ./coreutils.exe -e '*' -f coreutils.exe)"
        p.enterwine = "$(--path=absnative get-object CommonsBase_Win32.Wine@11.2.0 -s ${SLOTNAME.Release.execution_abi} -d : -e 'bin/*' -e 'lib/wine/*/*')${/}bin${/}enter-wine.sh"
        p.gawkexe = "$(get-object CommonsBase_GNU.Awk@5.3.1 -s Release.execution_abi -d : -e 'bin/*')${/}bin/gawk"
        p.gnutlslib = "$(--path=absnative get-object CommonsBase_GNU.TLS@3.8.12 -s $(get-asset CommonsBase_Win32.Lookup@1.0.0 -p winerunlib-slot -m ./${SLOTNAME.Release.execution_abi}) -d :)${/}lib"
        p.inotifylib = "$(--path=absnative get-object NotMatveevKondratyev_Libinotify.Kqueue@0.20240724.0 -s $(get-asset CommonsBase_Win32.Lookup@1.0.0 -p winerunlib-slot -m ./${SLOTNAME.Release.execution_abi}) -d :)${/}lib"
        p.krb5lib = "$(--path=absnative get-object NotMitEdu_Kerberos.V5@1.22.2 -s $(get-asset CommonsBase_Win32.Lookup@1.0.0 -p winerunlib-slot -m ./${SLOTNAME.Release.execution_abi}) -d :)${/}lib"

        local commands = {
            -- Do wineboot --init
            {
                "/bin/sh", p.enterwine, "--gnutls-libdir", p.gnutlslib, "--inotify-libdir", p.inotifylib, "--krb5-libdir", p.krb5lib,
                "--init", p.wenv
            },

            -- Wait until the wineserver process has exited to avoid race conditions modifying the wine prefix
            {
                "/bin/sh",
                "$(get-asset NotInriaCaml_Std.Lookup@1.0.0 -p s -m ./wait-wineserver.sh -f wait-wineserver.sh)"
            },

            -- Place OCaml in the wenv at C:\opt\ocaml-5.4.1
            { p.coreutilsexe, "mkdir", "-p", p.wenv .. "/drive_c/opt" },
            { p.coreutilsexe, "rm", "-rf", p.wenv .. "/drive_c/opt/ocaml-5.4.1" },
            {
                p.coreutilsexe,
                "cp", "-r",
                "$(get-object NotInriaCaml_Std.Toolchain.W64devkit@5.4.1 -s Release.execution_abi.Windows_x86_64 -d :)",
                p.wenv .. "/drive_c/opt/ocaml-5.4.1"
            },

            -- Place C compiler (w64devkit) in the wenv at C:\opt\w64devkit
            { p.coreutilsexe, "rm", "-rf", p.wenv .. "/drive_c/opt/w64devkit" },
            {
                p.coreutilsexe,
                "cp", "-r",
                "$(get-object CommonsBase_GNU.Toolchain.W64dev@2.5.0 -s Release.Windows_x86_64 -d :)",
                p.wenv .. "/drive_c/opt/w64devkit"
            },

            -- Place cygpath.cmd in the wenv at C:\opt\cygpath
            { p.coreutilsexe, "mkdir", "-p", p.wenv .. "/drive_m/opt/cygpath" },
            {
                p.coreutilsexe,
                "cp",
                "$(get-asset NotInriaCaml_Std.Lookup@1.0.0 -p s -m ./cygpath-winepath.cmd -f cygpath.cmd)",
                p.wenv .. "/drive_c/opt/cygpath/"
            },

            -- PATH: add cygpath, OCaml and w64devkit
            {
                "/bin/sh", p.enterwine, "--gnutls-libdir", p.gnutlslib, "--inotify-libdir", p.inotifylib, "--krb5-libdir", p.krb5lib,
                --      add to HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment which is:
                --          %SystemRoot%\system32;%SystemRoot%;%SystemRoot%\system32\wbem;%SystemRoot%\system32\WindowsPowershell\v1.0
                p.wenv,
                "REG", "ADD", "HKEY_CURRENT_USER\\Environment",
                "/t", "REG_EXPAND_SZ",
                "/f", -- no prompt for configuration
                "/v", "Path",
                "/d", "C:\\opt\\cygpath;C:\\opt\\ocaml-5.4.1\\bin;C:\\opt\\w64devkit\\bin"
            },

            -- create M: drive for mounting host directories
            -- https://gitlab.winehq.org/wine/wine/-/wikis/Wine-User's-Guide#drive-settings
            { p.coreutilsexe, "mkdir", "-p", p.wenv .. "/drive_m" },
            { p.coreutilsexe, "rm", "-f", p.wenv .. "/dosdevices/m:" },
            { p.coreutilsexe, "ln", "-s", "../drive_m", p.wenv .. "/dosdevices/m:" },

            -- remove all symlinks from M: drive (from a previous mount)
            {
                p.fdexe, "--glob", "--hidden", "--no-ignore",
                "--type", "l",
                "-X", p.coreutilsexe, "rm", "-f", ";",
                "--", "*", p.wenv .. "/drive_m"
            },

            -- create bin/enter with awk. replace placeholders with real values
            { p.coreutilsexe, "mkdir", "-p", p.wenv .. "/bin" },
            {
                p.gawkexe,
                "-v", "OUTPUT_FILE=" .. p.wenv .. "/bin/enter",
                "-v", "WINEHOME=$(--path=absnative get-object CommonsBase_Win32.Wine@11.2.0 -s ${SLOTNAME.Release.execution_abi} -d : -e 'bin/*' -e 'lib/wine/*/*')",
                "-v", "WINEPREFIX=" .. p.wenv,
                "-v", "GNUTLS_LIBDIR=" .. p.gnutlslib,
                "-v", "INOTIFY_LIBDIR=" .. p.inotifylib,
                "-v", "KRB5_LIBDIR=" .. p.krb5lib,
                "-f", "$(get-asset NotInriaCaml_Std.Lookup@1.0.0 -p s -m ./enter-wenv-mk.awk -f enter-wenv-mk.awk)",
                "$(get-asset NotInriaCaml_Std.Lookup@1.0.0 -p s -m ./enter-wenv.in.sh -f enter-wenv.sh)"
            },
            --   until we upgrade past coreutils 0.2.2, we have to search for chmod on PATH.
            -- { p.coreutilsexe, "chmod", "+x", p.wenv .. "/bin/enter" },
            { p.coreutilsexe, "env", "chmod", "+x", p.wenv .. "/bin/enter" },

            -- create a zero-byte output file (at least one output file is needed for a dk0 function)
            { p.coreutilsexe, "truncate", "--size=0", "${SLOT.request}/.complete" }
        }

        -- loop through any `mount[]` options and add commands to create the mounts in the wenv
        local k, v = next(p.mounts)
        while k do
            local mount = NotInriaCaml_Std__Wenv__0_1_0.parse_mount_option(v)

            -- verify the mount type is "bind"
            if mount.type ~= "bind" then
                error("Only bind mounts are supported, but got type=" .. mount.type)
            end

            -- verify the src is an absolute path on the host machine
            assert(NotInriaCaml_Std__Wenv__0_1_0.validate_absolutepath("The mount's [src]", mount.src))

            -- get Unix subpath on the M: drive
            local m_dst_subpath = NotInriaCaml_Std__Wenv__0_1_0.m_drive_unix_subpath(mount.dst)

            -- create command to create parent directory, if any
            local m_dst_parent = NotInriaCaml_Std__Wenv__0_1_0.unix_parent_dir(m_dst_subpath)
            if m_dst_parent ~= "" then
                table.insert(commands, {
                    p.coreutilsexe,
                    "mkdir", "-p", p.wenv .. "/drive_m/" .. m_dst_parent
                })
            end

            -- create command to symlink the mount
            print("Mounting host path " .. mount.src .. " at " .. mount.dst .. " in the wenv")
            table.insert(commands, {
                p.coreutilsexe,
                "ln", "-s", mount.src, p.wenv .. "/drive_m/" .. m_dst_subpath
            })

            k, v = next(p.mounts, k)
        end

        return {
            submit = {
                values = {
                    schema_version = { major = 1, minor = 0 },
                    forms = {
                        {
                            id = p.outputid,
                            function_ = {
                                commands = commands,
                            },
                            outputs = {
                                assets = {
                                    {
                                        slots = { "Release.Agnostic" },
                                        paths = { ".complete" }
                                    }
                                }
                            }
                        }
                    }
                },
                expressions = {
                    directories = {
                        form_was_created = "$(get-object " .. p.outputid .. " -s Release.Agnostic -d :)"
                    }
                }
            }
        }
    elseif command == "ui" then
        local wenv = assert(request.user.dir, "Expected `dir=WENV` on the command line")
        print("")
        print("")
        print("To enter the wenv, run the following command in your terminal:")
        print("  '" .. wenv .. "/bin/enter' <Windows command> [args...]")
        print("For example, to open a Windows command prompt and run OCaml in the wenv, run:")
        print("  $ '" .. wenv .. "/bin/enter' cmd.exe")
        print("  Microsoft Windows 10.0.19045")
        print("")
        print("  Z:\\> ocamlopt -config")
        print("  Z:\\> gcc --version")
        print("  Z:\\> ocaml")
        print("  OCaml version 5.4.1")
        print("  Enter #help;; for help.")
        print("")
        print("  # 1+1 ;;")
        print("  - : int = 2")
        print("  # ^Z")
        print("  Z:\\> echo let () = print_endline \"abcxyz\" > letters.ml")
        print("  Z:\\> ocamlopt -o letters.exe letters.ml")
        print("  Z:\\> .\\letters.exe")
        print("  abcxyz")
        print("  Z:\\> exit")
    end
end

function NotInriaCaml_Std__Wenv__0_1_0.parse_mount_option(option)
    local mount = {}
    local pos = 1
    local len = string.len(option)
    local break_ = 0
    while pos <= len and break_ == 0 do
        local eq_start, eq_end = string.find(option, "=", pos, 1)
        if eq_start then
            local key = string.sub(option, pos, eq_start - 1)
            local comma_start, comma_end = string.find(option, ",", eq_end + 1, 1)
            local value
            if comma_start then
                value = string.sub(option, eq_end + 1, comma_start - 1)
                pos = comma_end + 1
            else
                value = string.sub(option, eq_end + 1)
                pos = len + 1
            end
            mount[key] = value
        else
            break_ = 1
        end
    end

    if not mount.type or not mount.src or not mount.dst then
        error("Mount option must include type, src, and dst: " .. option)
    end
    return mount
end

-- translate a Windows path on the M: drive to the corresponding Unix path in the wenv
-- ex. M:\path\in\wenv -> path/in/wenv
function NotInriaCaml_Std__Wenv__0_1_0.m_drive_unix_subpath(path)
    if string.sub(path, 1, 3) ~= "M:\\" and string.sub(path, 1, 3) ~= "M:/" then
        error("Path must be on the M: drive (ex. M:\\path\\in\\wenv, M:/otherpath/in/wenv), not " .. path)
    end
    local relative = string.sub(path, 4)

    -- translate Windows path to Unix path
    local unix = ""
    local pos = 1
    local len = string.len(relative)
    while pos <= len do
        local sep_start, sep_end = string.find(relative, "\\", pos, 1)
        if sep_start then
            unix = unix .. "/" .. string.sub(relative, pos, sep_start - 1)
            pos = sep_end + 1
        else
            unix = unix .. "/" .. string.sub(relative, pos)
            pos = len + 1
        end
    end

    -- remove leading slashes
    while string.sub(unix, 1, 1) == "/" do
        unix = string.sub(unix, 2)
    end

    -- remove trailing slashes
    while string.sub(unix, -1) == "/" do
        unix = string.sub(unix, 1, -2)
    end

    -- must be a real subpath of M:/
    local unix_sanitized = assert(stringdk.sanitizesubpath (unix))

    return unix_sanitized
end

-- get the parent directory of a Unix path (ex. path/in/wenv -> path/in)
function NotInriaCaml_Std__Wenv__0_1_0.unix_parent_dir(path)
    local sep_start, sep_end = string.find(path, "/", 1, true)
    if sep_start then
        return string.sub(path, 1, sep_start - 1)
    else
        return ""
    end
end

function NotInriaCaml_Std__Wenv__0_1_0.validate_absolutepath(what, path)
    if string.sub(path, 1, 1) == "/" then
        return 1
    else
        return nil, what .. " must be an absolute path starting with `/`, but got `" .. path .. "`"
    end
end

return M
