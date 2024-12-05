module Arg = Tr1Stdlib_V414CRuntime.Arg
module Bos = Tr1Bos_Std.Bos
module Printf = Tr1Stdlib_V414CRuntime.Printf
module Logs = Tr1Logs_Std.Logs
module StdExit = Tr1Stdlib_V414CRuntime.StdExit
module String = Tr1Stdlib_V414Base.String
module Sys = Tr1Stdlib_V414CRuntime.Sys
let prerr_endline = Tr1Stdlib_V414Io.StdIo.prerr_endline
let exit = Tr1Stdlib_V414CRuntime.StdExit.exit

let verbose = ref false
let project_dir = ref ""
let anon_fun s = if !project_dir = "" then project_dir := s

let usage_msg = "DkStd_Std.Project.Init [-verbose] PROJECT_DIR"
let speclist =
  [
    ("-verbose", Arg.Set verbose, "Output debug information");
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
      Printf.eprintf "dkcoder: %s\n%!" (String.concat " " ("git" :: args));
    let git_exe =
      match Slots.git slots with
      | Some exe -> Cmd.(v (p exe))
      | None -> Cmd.(v "git")
    in
    let git_exe =
      match alt_project_dir with
      | None -> Cmd.(git_exe % "-C" % !project_dir)
      | Some alt_project_dir -> Cmd.(git_exe % "-C" % alt_project_dir)
    in
    OS.Cmd.run Cmd.(git_exe %% of_list args) |> rmsg

  let git_out ?quiet ?alt_project_dir ~slots args =
    let open Bos in
    if !verbose && quiet = None then
      Printf.eprintf "dkcoder: %s\n%!" (String.concat " " ("git" :: args));
    let git_exe =
      match Slots.git slots with
      | Some exe -> Cmd.(v (p exe))
      | None -> Cmd.(v "git")
    in
    let git_exe =
      match alt_project_dir with
      | None -> Cmd.(git_exe % "-C" % !project_dir)
      | Some alt_project_dir -> Cmd.(git_exe % "-C" % alt_project_dir)
    in
    let out, _status =
      OS.Cmd.run_out Cmd.(git_exe %% of_list args) |> OS.Cmd.out_string |> rmsg
    in
    String.trim out
end

let contents_gitignore_untrimmed = {|
# DkCoder intermediate files
/#s/
/_build/
/.z-dk-dune-project
/dune-workspace
|}

let () =
  Arg.parse speclist anon_fun usage_msg;
  if !project_dir = "" then Utils.fail "PROJECT_DIR argument is missing";

  let slots = Slots.create () in

  let project_dirp = Fpath.v !project_dir in
  if not (Bos.OS.Dir.exists project_dirp |> Utils.rmsg) then
    Printf.ksprintf Utils.fail "PROJECT_DIR %s does not exist" !project_dir;

  (* git init *)
  if not (Bos.OS.Dir.exists Fpath.(project_dirp / ".git") |> Utils.rmsg) then
    Utils.git ~slots ["init"; "--quiet"; "--initial-branch=main"];
  
  (* dk, dk.cmd, __dk.cmake, .gitattributes *)
  let copy_if ?mode s = 
    let dest = Fpath.(project_dirp / s) in
    if not (Bos.OS.File.exists dest |> Utils.rmsg) then (
      Printf.eprintf "dkcoder: create %s\n%!" s;
      DkFs_C99.File.copy ?mode ~src:(Fpath.v s) ~dest () |> Utils.rmsg)
  in
  copy_if ~mode:0o755 "dk";
  copy_if "dk.cmd";
  copy_if "__dk.cmake";
  copy_if ".gitattributes";

  (* .gitignore *)
  let gitignore = Fpath.(project_dirp / ".gitignore") in
  if not (Bos.OS.File.exists gitignore |> Utils.rmsg) then (
    Printf.eprintf "dkcoder: create .gitignore\n%!";
    Bos.OS.File.write gitignore (String.trim contents_gitignore_untrimmed) |> Utils.rmsg);

  (* git add, git update-index *)
  let files = ["dk"; "dk.cmd"; "__dk.cmake"; ".gitattributes"; ".gitignore"] in
  Utils.git ~quiet:() ~slots ("add" :: files);
  Utils.git ~quiet:() ~slots ["update-index"; "--chmod=+x"; "dk"];

  (* fail fast if there are any changes in the dkcoder project. We don't want to delete modifications. *)
  let dkcoder_project_dir = Sys.getcwd () in
  let git_status = Utils.git_out ~quiet:() ~alt_project_dir:dkcoder_project_dir ~slots ["status"; "--short"] in
  match git_status with
  | "" ->
    Utils.git ~quiet:() ~slots ("status" :: "--short" :: files)
  | changes ->  
    Printf.eprintf "dkcoder: The dkcoder/ project has changes:\n";
    prerr_endline changes;
    Utils.fail "dkcoder: The dkcoder/ project will not be deleted."
