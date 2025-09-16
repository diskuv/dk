(*************************************************************************
 * File: dkcoder/src/DkStd_Std/Project/Init.ml                           *
 *                                                                       *
 * Copyright 2025 Diskuv, Inc.                                           *
 *                                                                       *
 * Licensed under the Open Software License version 3.0                  *
 * (the "License"); you may not use this file except in compliance       *
 * with the License. You may obtain a copy of the License at             *
 *                                                                       *
 *     https://opensource.org/license/osl-3-0-php/                       *
 *                                                                       *
 *************************************************************************)

module Arg = Tr1Stdlib_V414CRuntime.Arg
module Bos = Tr1Bos_Std.Bos
module Format = Tr1Stdlib_V414CRuntime.Format
module Printf = Tr1Stdlib_V414CRuntime.Printf
module List = Tr1Stdlib_V414Base.List
module Logs = Tr1Logs_Std.Logs
module Map = Tr1Stdlib_V414Base.Map
module Out_channel = Tr1Stdlib_V414CRuntime.Out_channel
module StdExit = Tr1Stdlib_V414CRuntime.StdExit
module String = Tr1Stdlib_V414Base.String
module Stringext = Tr1String_Ext.Stringext
module Sys = Tr1Stdlib_V414CRuntime.Sys
let prerr_endline = Tr1Stdlib_V414Io.StdIo.prerr_endline
let exit = Tr1Stdlib_V414CRuntime.StdExit.exit

module StringMap = Map.Make (String)

let verbose = ref false
let windows_boot = ref false
let delete_dkcoder_after = ref false
let new_project_dir = ref ""
let dkcoder_project_dir = ref ""
let module_id_contents = ref StringMap.empty

let anon_fun s =
  if !new_project_dir = "" then
    new_project_dir := s
  else if !dkcoder_project_dir = "" then
    dkcoder_project_dir := s
  else
      match Stringext.cut ~on:"=" s with
      | None -> ()
      | Some (module_id, _contents_or_filename) ->
        module_id_contents := StringMap.add module_id "" !module_id_contents

let usage_msg = "DkStd_Std.Project.Init [-verbose] [-windows-boot] [-delete-dkcoder-after] NEW_PROJECT_DIR DKCODER_PROJECT_DIR [MODULE_ID1=] [MODULE_ID2=] ..."
let speclist =
  [
    ("-verbose", Arg.Set verbose, "Output debug information.");
    ("-delete-dkcoder-after", Arg.Set delete_dkcoder_after, "Delete the DKCODER_PROJECT_DIR after the NEW_PROJECT_DIR is initialized.");
    ("-windows-boot", Arg.Set windows_boot, "Do git init if necessary and then copy dk.cmd. No other steps are performed. The copied scripts are all that are necessary to run `DkStd_Std.Project.Init -delete-dkcoder-after`. The separate step is necessary so that the running dk.cmd is not deleted, which Command Prompt does not support.");
  ]


module Slots = struct
  (** Accumulator of paths as programs and directories are found. *)

  type t = { git : Fpath.t option; paths : Fpath.t list }

  let create () = { git = None; paths = [] }

  let add_git t git_exe =
    let fp_dir = Fpath.parent git_exe in
    { git = Some git_exe; paths = fp_dir :: t.paths }

  let add_path t path = { t with paths = path :: t.paths }
  let paths { paths; _ } = paths
  let git { git; _ } = git
end

module Utils = struct
  (** {1 Error Handling}  *)

  let fail msg = prerr_endline msg; exit 2
  let rmsg = function Ok v -> v | Error (`Msg msg) -> fail msg

  (** {1 Running git} *)

  let git ?quiet ?alt_project_dir ~slots args =
    let open Bos in
    if !verbose && quiet = None then
      Printf.eprintf "dk: %s\n%!" (String.concat " " ("git" :: args));
    let git_exe =
      match Slots.git slots with
      | Some exe -> Cmd.(v (p exe))
      | None -> Cmd.(v "git")
    in
    let git_exe =
      match alt_project_dir with
      | None -> Cmd.(git_exe % "-C" % !new_project_dir)
      | Some alt_project_dir -> Cmd.(git_exe % "-C" % alt_project_dir)
    in
    OS.Cmd.run Cmd.(git_exe %% of_list args) |> rmsg

  let git_out ?quiet ?alt_project_dir ~slots args =
    let open Bos in
    if !verbose && quiet = None then
      Printf.eprintf "dk: %s\n%!" (String.concat " " ("git" :: args));
    let git_exe =
      match Slots.git slots with
      | Some exe -> Cmd.(v (p exe))
      | None -> Cmd.(v "git")
    in
    let git_exe =
      match alt_project_dir with
      | None -> Cmd.(git_exe % "-C" % !new_project_dir)
      | Some alt_project_dir -> Cmd.(git_exe % "-C" % alt_project_dir)
    in
    OS.Cmd.run_out Cmd.(git_exe %% of_list args) |> OS.Cmd.out_string |> OS.Cmd.success |> rmsg
end

let contents_gitignore_untrimmed = {|
# DkCoder intermediate files
/#s/
/_build/
/.z-dk-dune-project
/dune-workspace
/.merlin
|}

(* SYNC: src/DkStd_Std/Project/Init.ml, .vscode/settings.json *)
let contents_settings_json_untrimmed = {|
{
    "ocaml.sandbox": {
        "kind": "custom",
        "template": "${firstWorkspaceFolder}/dk -g dune-ide --fixed-length-modules false RunQuiet Ml.Exec --merlin -- $prog $args"
    }
}|}

let contents_extensions_json_untrimmed = {|
{
    "recommendations": [
        "ocamllabs.ocaml-platform"
    ]
}|}

let contents_ocamlformat_untrimmed = {|
profile=conventional
exp-grouping=preserve
nested-match=align
|}

let write_crlf_on_win32 fp s =
  Out_channel.with_open_text (Fpath.to_string fp) (fun oc ->
    Out_channel.output_string oc s)

let () =
  Arg.parse speclist anon_fun usage_msg;
  if !new_project_dir = "" then Utils.fail "NEW_PROJECT_DIR argument is missing";
  if !dkcoder_project_dir = "" then Utils.fail "DKCODER_PROJECT_DIR argument is missing";

  let slots = Slots.create () in

  let new_project_dirp = Fpath.v !new_project_dir in
  let dkcoder_project_dirp = Fpath.v !dkcoder_project_dir in
  if not (Bos.OS.Dir.exists new_project_dirp |> Utils.rmsg) then
    Printf.ksprintf Utils.fail "NEW_PROJECT_DIR %s does not exist" !new_project_dir;
  if not (Bos.OS.Dir.exists dkcoder_project_dirp |> Utils.rmsg) then
    Printf.ksprintf Utils.fail "DKCODER_PROJECT_DIR %s does not exist" !dkcoder_project_dir;

  (* git init *)
  if not (Bos.OS.Dir.exists Fpath.(new_project_dirp / ".git") |> Utils.rmsg) then
    Utils.git ~slots ["init"; "--quiet"; "--initial-branch=main"];

  (* dk, dk.cmd, .gitattributes *)
  let copy_if ?mode s =
    let src = Fpath.(dkcoder_project_dirp / s) in
    let dest = Fpath.(new_project_dirp / s) in
    if not (Bos.OS.File.exists dest |> Utils.rmsg) then (
      Printf.eprintf "dk: create %s\n%!" s;
      DkFs_C99.File.copy ?mode ~src ~dest () |> Utils.rmsg)
  in
  copy_if "dk.cmd";
  (*    Stop here if [windows_boot]. *)
  if !windows_boot then exit 0;
  copy_if ~mode:0o755 "dk";
  copy_if ".gitattributes";

  (* .gitignore *)
  let gitignore = Fpath.(new_project_dirp / ".gitignore") in
  if not (Bos.OS.File.exists gitignore |> Utils.rmsg) then (
    Printf.eprintf "dk: create .gitignore\n%!";
    (* Use CRLF on Windows since ".gitignore text" in .gitattributes *)
    write_crlf_on_win32 gitignore (String.trim contents_gitignore_untrimmed));

  (* .ocamlformat *)
  let ocamlformat = Fpath.(new_project_dirp / ".ocamlformat") in
  if not (Bos.OS.File.exists ocamlformat |> Utils.rmsg) then (
    Printf.eprintf "dk: create .ocamlformat\n%!";
    (* Use CRLF on Windows since ".ocamlformat text" in .gitattributes *)
    write_crlf_on_win32 ocamlformat (String.trim contents_ocamlformat_untrimmed));

  (* .vscode/ *)
  let vscode_dirp = Fpath.(new_project_dirp / ".vscode") in
  Bos.OS.Dir.create vscode_dirp |> Utils.rmsg |> ignore;

  (* .vscode/extensions.json *)
  let extensions_json = Fpath.(vscode_dirp / "extensions.json") in
  if not (Bos.OS.File.exists extensions_json |> Utils.rmsg) then (
    Printf.eprintf "dk: create .vscode/extensions.json\n%!";
    (* Use CRLF on Windows since .json are "*.json text" in .gitattributes *)
    write_crlf_on_win32 extensions_json (String.trim contents_extensions_json_untrimmed));

  (* .vscode/settings.json *)
  let settings_json = Fpath.(vscode_dirp / "settings.json") in
  if not (Bos.OS.File.exists settings_json |> Utils.rmsg) then (
    Printf.eprintf "dk: create .vscode/settings.json\n%!";
    (* Use CRLF on Windows since .json are "*.json text" in .gitattributes *)
    write_crlf_on_win32 settings_json (String.trim contents_settings_json_untrimmed));

  (* src/**.ml *)
  let source_files = List.filter_map (fun (module_id, content) ->
    let ml_file =
      let src_mod = "src" :: Stringext.split ~on:'.' module_id in
      (String.concat "/" src_mod) ^ ".ml"
    in
    match Fpath.of_string ml_file with
    | Error (`Msg msg) -> Printf.eprintf "dk: INVALID module id: %s. %s\n%!" module_id msg; exit 4
    | Ok fp ->
      let abs_fp = Fpath.(new_project_dirp // fp) in
      Bos.OS.Dir.create (Fpath.parent abs_fp) |> Utils.rmsg |> ignore;
      Bos.OS.File.write abs_fp content |> Utils.rmsg;
      Some ml_file)
    (StringMap.bindings !module_id_contents)
  in

  (* git add, git update-index *)
  let project_files = ["dk"; "dk.cmd"; 
    ".gitattributes"; ".gitignore";
    ".ocamlformat";
    ".vscode/settings.json"; ".vscode/extensions.json"]
    @ source_files
  in
  Utils.git ~quiet:() ~slots ("add" :: project_files);
  Utils.git ~quiet:() ~slots ["update-index"; "--chmod=+x"; "dk"];

  (* fail fast if there are any changes in the dkcoder project. We don't want to delete modifications! *)
  let changes = Utils.git_out ~quiet:() ~alt_project_dir:!dkcoder_project_dir ~slots ["status"; "--short"] in
  if String.trim changes <> "" then begin
    Printf.eprintf "dk: The %s project has changes and will not be deleted:\n" !dkcoder_project_dir;
    Format.eprintf "@[<v 2>   %a@]@." Fmt.lines changes;
    exit 3
  end;

  (* fail fast if there are any unpushed commits in the dkcoder project. We don't want to delete modifications!
     technique: https://stackoverflow.com/a/3338774 *)
  let unpushed = Utils.git_out ~quiet:() ~alt_project_dir:!dkcoder_project_dir ~slots ["log"; "--branches"; "--not"; "--remotes"; "--simplify-by-decoration"; "--decorate"; "--oneline"] in
  if String.trim unpushed <> "" then begin
    Printf.eprintf "dk: The %s project has unpushed commits and will not be deleted:\n" !dkcoder_project_dir;
    Format.eprintf "@[<v 2>   %a@]@." Fmt.lines unpushed;
    exit 3
  end;

  (* Delete the dkcoder project if requested *)
  if !delete_dkcoder_after then
    DkFs_C99.Path.rm ~recurse:() ~force:() [ dkcoder_project_dirp ] |> Utils.rmsg;

  (* Display the status of the project files *)
  Utils.git ~quiet:() ~slots ("status" :: "--short" :: project_files)
