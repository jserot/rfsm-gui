(* VHDL backend *)

open Utils
open Fsm
open Types
open Printf
open Cmodel

exception Vhdl_error of string * string  (* where, msg *)

type vhdl_config = {
  mutable vhdl_lib_name: string;
  mutable vhdl_lib_dir: string;
  mutable vhdl_inpmod_prefix: string;
  mutable vhdl_tb_name: string;
  mutable vhdl_state_var: string;
  mutable vhdl_stop_time: int;
  mutable vhdl_time_unit: string;
  mutable vhdl_reset_sig: string;
  mutable vhdl_reset_duration: int;
  mutable vhdl_ev_duration: int;
  mutable vhdl_default_int_type: string;
  mutable vhdl_default_int_size: int;
  mutable vhdl_support_library: string;
  mutable vhdl_support_package: string;
  mutable vhdl_trace: bool;
  mutable vhdl_use_variables: bool;
  mutable vhdl_trace_state_var: string
  }

let cfg = {
  vhdl_lib_name = "rfsm";
  vhdl_lib_dir = ".";
  vhdl_inpmod_prefix = "inp_";
  vhdl_tb_name = "tb";
  vhdl_state_var = "state";
  vhdl_stop_time = 100;
  vhdl_reset_sig = "rst";
  vhdl_time_unit = "ns";
  vhdl_reset_duration = 1;
  vhdl_ev_duration = 1;
  vhdl_default_int_type = "unsigned";
  vhdl_default_int_size = 8;
  vhdl_support_library = "rfsm";
  vhdl_support_package = "core";
  vhdl_trace = false;
  vhdl_use_variables = false;
  vhdl_trace_state_var = "st";
  }

let rec  bit_size n = if n=0 then 0 else 1 + bit_size (n/2)
let max x y = if x > y then x else y

type vhdl_type = 
    Std_logic 
  | Unsigned of int
  | Signed of int
  | Integer

let rec vhdl_type_of t = match t with 
  | TyEvent -> Std_logic
  | TyBool -> Std_logic
  | TyEnum cs -> Error.not_implemented "VHDL translation of enumerated type"
  | TyInt None -> Integer
(*       begin match cfg.vhdl_default_int_type with *)
(*         "signed" -> Signed cfg.vhdl_default_int_size *)
(*       | _ -> Unsigned cfg.vhdl_default_int_size *)
(*       end *)
  | TyInt (Some (TiConst lo,TiConst hi)) ->
      if lo < 0 then Signed (bit_size (max (-lo) hi)) else Unsigned (bit_size hi)
  | TyInt _
  | _ ->
     Error.fatal_error "Vhdl.vhdl_type_of"

let rec string_of_vhdl_type t = match t with 
  | Std_logic -> "std_logic"
  | Unsigned n -> Printf.sprintf "unsigned(%d downto 0)" (n-1)
  | Signed n -> Printf.sprintf "signed(%d downto 0)" (n-1)
  | Integer -> "integer"

let string_of_type t = string_of_vhdl_type (vhdl_type_of t)


let global_types = ref ( [] : (string * vhdl_type) list )

(* exception Type_of_value *)
        
(* let type_of_value v = match v with *)
(*   Expr.Val_int _ -> "integer" *)
(* | Expr.Val_enum _ -> raise Type_of_value *)

let lookup_type id = 
  try Some (List.assoc id !global_types)
  with Not_found -> None
(*   with Not_found -> raise (Error ("", "cant retrieve VHDL type for id " ^ id) *)

let type_error where what item ty1 ty2 = 
  raise (Vhdl_error(
     where,
     Printf.sprintf "incompatible types for %s \"%s\": %s and %s"
       what item (string_of_vhdl_type ty1) (string_of_vhdl_type ty2)))

let add_type (id,ty) =
  try
    let ty' = List.assoc id !global_types in
    if ty' <> ty then type_error "" "id" id ty ty'
  with Not_found ->
    global_types := (id,ty) :: !global_types

let reset_types () = global_types := []

let string_of_value ?(ty=None) v = match v, ty with
  Expr.Val_int i, Some (Unsigned n) -> Printf.sprintf "to_unsigned(%d,%d)" i n
| Expr.Val_int i, Some (Signed n) -> Printf.sprintf "to_signed(%d,%d)" i n
| Expr.Val_int i, Some Std_logic -> Printf.sprintf "'%d'" i
| Expr.Val_int i, Some Integer -> Printf.sprintf "%d" i
| Expr.Val_int i, None -> Printf.sprintf "%d" i
| Expr.Val_bool b, _ -> string_of_bool b
| Expr.Val_enum s, _ -> Error.not_implemented "VHDL translation of enumerated value"

let string_of_ival ?(ty=None) = function
    None -> ""
  | Some v -> " = " ^ string_of_value ~ty:ty v

let rec type_of_expr e = match e with
    Expr.EInt c -> None (* too late .. *)
  | Expr.EBool c -> Some (vhdl_type_of TyBool)
  | Expr.EEnum c -> None
  | Expr.EVar n -> lookup_type n 
  | Expr.EBinop (op,e1,e2) -> 
      begin match type_of_expr e1, type_of_expr e2 with
        None, None -> None
      | Some t1, None -> Some t1
      | None, Some t2 -> Some t2
      | Some t1, Some t2 -> 
          if t1 = t2 then Some t1
          else type_error "" "binary operation" op t1 t2
      end

let vhdl_string_of_int ?(ty=None) n =
  match ty with
    Some (Unsigned s) -> Printf.sprintf "to_unsigned(%d,%d)" n s
  | Some (Signed s) -> Printf.sprintf "to_signed(%d,%d)" n s
  | Some Std_logic -> Printf.sprintf "'%d'" n
  | _ -> string_of_int n (* will probably not compile but can't do better at this level.. *)

let rec string_of_expr ?(ty=None) e = match e with
    Expr.EInt c -> vhdl_string_of_int ~ty:ty  c
  | Expr.EBool c -> string_of_bool c
  | Expr.EEnum c -> c
  | Expr.EVar n ->  n
  | Expr.EBinop (op,e1,e2) -> 
      let ty = type_of_expr e in
      begin match op, ty with 
        "*", Some (Signed _)
      | "*", Some (Unsigned _) ->  "mul(" ^ string_of_expr ~ty:ty e1 ^ "," ^ string_of_expr ~ty:ty e2 ^ ")"
      | _, _ -> string_of_expr ~ty:ty e1 ^ string_of_op op ^ string_of_expr ~ty:ty e2 (* TODO : add parens *)
      end
                                                                      
and string_of_op = function
    "=" -> " = "
  | "!=" -> " /= "
  | "mod" -> " mod "
  | op ->  op

(* type vhdl_kind = Vhdl_signal | Vhdl_variable *)

let string_of_action ?(lvars=[]) a = match a with
  | Action.Assign (id, expr) ->
     let asn = if List.mem_assoc id lvars && cfg.vhdl_use_variables then " := " else " <= " in
     let ty = lookup_type id in
     id ^ asn ^ string_of_expr ~ty:ty expr
    | Action.Emit id -> "notify_ev(" ^ id ^ "," ^ (string_of_int cfg.vhdl_ev_duration) ^ " " ^ cfg.vhdl_time_unit ^ ")"
    | Action.StateMove (id,s,s') -> "" (* should not happen *)

let string_of_condition (e,cs) =  
  let string_of_guard (e,op,e') =
      let ty = type_of_expr (Expr.EBinop (op,e,e')) in 
      string_of_expr ~ty:ty e ^ string_of_op op ^ string_of_expr ~ty:ty e' in
  match cs with
    [] -> failwith "Vhdl.string.of_condition"
  | _ -> ListExt.to_string string_of_guard " and " cs

let dump_action ?(lvars=[]) oc tab a = fprintf oc "%s%s;\n" tab (string_of_action ~lvars:lvars a)

let dump_transition ?(lvars=[]) oc tab src clk (is_first,needs_endif) (q',(cond,acts,_)) =
  match cond with
    _, [] -> 
       List.iter (dump_action ~lvars:lvars oc tab) acts;
       fprintf oc "%s%s <= %s;\n" tab cfg.vhdl_state_var q';
       (false,false)
  | _, _ ->
       fprintf oc "%s%s ( %s ) then\n" tab (if is_first then "if" else "elsif ") (string_of_condition cond);
       List.iter (dump_action ~lvars:lvars oc (tab ^ "  ")) acts;
       if q' <> src then fprintf oc "%s  %s <= %s;\n" tab cfg.vhdl_state_var q';
       (false,true)

let dump_sync_transitions ?(lvars=[]) oc src after clk ts =
   let tab = "        " in
   let (_,needs_endif) = List.fold_left (dump_transition ~lvars:lvars oc tab src clk) (true,false) ts in
   if needs_endif then fprintf oc "        end if;\n"
     
let dump_state oc clk m { st_src=q; st_sensibility_list=evs; st_transitions=tss } =
  match tss with
    [ev,ts] -> dump_sync_transitions ~lvars:m.c_vars oc q false clk ts
  | _ -> Error.not_implemented "VHDL: transitions involving multiple events"

let dump_state_case oc clk m c =
    fprintf oc "      when %s =>\n" c.st_src;
    dump_state oc clk m c

let dump_module_arch oc m fsm =
  let m = Cmodel.c_model_of_fsm m fsm in
  let modname = m.c_name in
  let _ = reset_types () in
  List.iter (function (id,ty) -> add_type (id, vhdl_type_of ty)) m.c_inps;
  List.iter (function (id,ty) -> add_type (id, vhdl_type_of ty)) m.c_outps;
  List.iter (function (id,ty) -> add_type (id, vhdl_type_of ty)) m.c_inouts;
  List.iter (function (id,(ty,_)) -> add_type (id, vhdl_type_of ty)) m.c_vars;
  let clk_sig = match List.filter (function (_, TyEvent) -> true | _ -> false) m.c_inps with
    [] -> raise (Vhdl_error (m.c_name, "no input event, hence no possible clock"))
  | [h,_] -> h
  | _ -> Error.not_implemented (m.c_name ^ ": translation to VHDL of FSM with more than one input events") in
  fprintf oc "architecture RTL of %s is\n" modname;
  fprintf oc "  type t_%s is ( %s );\n" cfg.vhdl_state_var (ListExt.to_string (function s -> s) ", " m.c_states);
  fprintf oc "  signal %s: t_state;\n" cfg.vhdl_state_var;
  if not cfg.vhdl_use_variables then 
    List.iter
      (fun (id,(ty,iv)) -> fprintf oc "  signal %s: %s;\n" id (string_of_type ty))
      m.c_vars;
  fprintf oc "begin\n";
  fprintf oc "  process(%s, %s)\n" cfg.vhdl_reset_sig clk_sig;
  if cfg.vhdl_use_variables then 
    List.iter
      (fun (id,(ty,iv)) -> fprintf oc "  variable %s: %s;\n" id (string_of_type ty))
      m.c_vars;
  fprintf oc "  begin\n";
  fprintf oc "    if ( %s='1' ) then\n" cfg.vhdl_reset_sig;
  fprintf oc "      %s <= %s;\n" cfg.vhdl_state_var (fst m.c_init);
  List.iter (dump_action ~lvars:m.c_vars oc "      ") (snd m.c_init);
  fprintf oc "    elsif rising_edge(%s) then \n" clk_sig;
  begin match m.c_body with
    [] -> () (* should not happen *)
  | [q] -> dump_state oc clk_sig m q 
  | qs -> 
      fprintf oc "      case %s is\n" cfg.vhdl_state_var;
      List.iter (dump_state_case oc clk_sig m) m.c_body;
      fprintf oc "    end case;\n"
  end;
  fprintf oc "    end if;\n";
  fprintf oc "  end process;\n";
  if cfg.vhdl_trace then begin
    let int_of_vhdl_state m =
      ListExt.to_string
        (function (s,i) -> string_of_int i ^ " when " ^ cfg.vhdl_state_var ^ "=" ^ s)
        " else "
        (List.mapi (fun i s -> s,i) m.c_states) in
    fprintf oc "  %s <= %s;\n" cfg.vhdl_trace_state_var (int_of_vhdl_state m)
    end;
  fprintf oc "end RTL;\n"

let dump_module_intf kind oc m fsm = 
  let m = Cmodel.c_model_of_fsm m fsm in
  let modname = m.c_name in
  fprintf oc "%s %s %s\n" kind modname (if kind = "entity" then "is" else "");
  fprintf oc "  port(\n";
  List.iter (fun (id,ty) -> fprintf oc "        %s: in %s;\n" id (string_of_type ty)) m.c_inps;
  List.iter (fun (id,ty) -> fprintf oc "        %s: out %s;\n" id (string_of_type ty)) m.c_outps;
  List.iter (fun (id,ty) -> fprintf oc "        %s: inout %s;\n" id (string_of_type ty)) m.c_inouts;
  fprintf oc "        %s: in std_logic" cfg.vhdl_reset_sig;
  if cfg.vhdl_trace then fprintf oc ";\n        %s: out integer\n" cfg.vhdl_trace_state_var else fprintf oc "\n";
  fprintf oc "        );\n";
  fprintf oc "end %s;\n" (if kind = "entity" then modname else kind)

(* Dumping input generator processes *)

let string_of_time t = string_of_int t ^ " " ^ cfg.vhdl_time_unit

let dump_sporadic_inp_process oc id ts =
       fprintf oc "    type t_dates is array ( 0 to %d ) of time;\n" (List.length ts-1);
       fprintf oc "    constant dates : t_dates := ( %s );\n" (ListExt.to_string string_of_time ", " ts);
       fprintf oc "    variable i : natural := 0;\n";
       fprintf oc "    variable t : time := 0 %s;\n" cfg.vhdl_time_unit;
       fprintf oc "    begin\n";
       fprintf oc "      %s <= '0';\n" id;
       fprintf oc "      for i in 0 to %d loop\n" (List.length ts-1);
       fprintf oc "        wait for dates(i)-t;\n";
       fprintf oc "        notify_ev(%s,%d %s);\n" id cfg.vhdl_ev_duration cfg.vhdl_time_unit;
       fprintf oc "        t := dates(i);\n";
       fprintf oc "      end loop;\n";
       fprintf oc "      wait;\n"

let dump_periodic_inp_process oc id (p,t1,t2) =
       fprintf oc "    type t_periodic is record period: time; t1: time; t2: time; end record;\n";
       fprintf oc "    constant periodic : t_periodic := ( %s, %s, %s );\n"
               (string_of_time (p-cfg.vhdl_ev_duration))
               (string_of_time t1)
               (string_of_time t2);
       fprintf oc "    variable t : time := 0 %s;\n" cfg.vhdl_time_unit;
       fprintf oc "    begin\n";
       fprintf oc "      %s <= '0';\n" id;
       fprintf oc "      wait for periodic.t1;\n";
       fprintf oc "      notify_ev(%s,%d %s);\n" id cfg.vhdl_ev_duration cfg.vhdl_time_unit;
       fprintf oc "      while ( t < periodic.t2 ) loop\n";
       fprintf oc "        wait for periodic.period;\n";
       fprintf oc "        notify_ev(%s,%d %s);\n" id cfg.vhdl_ev_duration cfg.vhdl_time_unit;
       fprintf oc "        t := t + periodic.period;\n";
       fprintf oc "      end loop;\n";
       fprintf oc "      wait;\n"
  
let dump_vc_inp_process oc id vcs =
       let ty = match lookup_type id with
         | Some t -> t 
         | None -> failwith ("Vhdl.dump_vc_inp_process: cannot retrieve type for identifier " ^ id) in
       let string_of_vc (t,v) = "(" ^ string_of_int t ^ " " ^ cfg.vhdl_time_unit ^ "," ^ string_of_value ~ty:(Some ty) v ^ ")" in
       fprintf oc "    type t_vc is record date: time; val: %s; end record;\n" (string_of_vhdl_type ty);
       fprintf oc "    type t_vcs is array ( 0 to %d ) of t_vc;\n" (List.length vcs-1);
       fprintf oc "    constant vcs : t_vcs := ( %s%s );\n"
               (if List.length vcs = 1 then "others => " else "")  (* GHDL complains when initializing a 1-array *)
               (ListExt.to_string string_of_vc ", " vcs);
       fprintf oc "    variable i : natural := 0;\n";
       fprintf oc "    variable t : time := 0 %s;\n" cfg.vhdl_time_unit;
       fprintf oc "    begin\n";
       fprintf oc "      for i in 0 to %d loop\n" (List.length vcs-1);
       fprintf oc "        wait for vcs(i).date-t;\n";
       fprintf oc "        %s <= vcs(i).val;\n" id;
       fprintf oc "        t := vcs(i).date;\n";
       fprintf oc "      end loop;\n";
       fprintf oc "      wait;\n"

let dump_input_process oc (id,(ty,desc)) =
  let open Comp in
  fprintf oc "  inp_%s: process\n" id;
  begin match desc with
    | MInp ({sd_comprehension=Sporadic ts}, _) -> dump_sporadic_inp_process oc id ts
    | MInp ({sd_comprehension=Periodic (p,t1,t2)}, _) -> dump_periodic_inp_process oc id (p,t1,t2)
    | MInp ({sd_comprehension=ValueChange []}, _) -> ()
    | MInp ({sd_comprehension=ValueChange vcs}, _) -> dump_vc_inp_process oc id vcs 
    | _ -> failwith "Vhdl.dump_inp_module_arch" (* should not happen *) end;
  fprintf oc "  end process;\n"

(* Dumping the testbench *)

(* let tb_name s = "t_" ^ s *)
let tb_name s = s

(* let dump_stimulus oc (id,v) =  *)
(*   match v with *)
(*   | Some v' -> fprintf oc "    %s <= %s;\n" (tb_name id) (string_of_value ~ty:(lookup_type id) v') *)
(*   | None -> Error.fatal_error "Vhdl.dump_stimulus"  (\* should not happen after transformation of events into signals *\) *)

(* let mk_events stimuli =  *)
(*   (\* Transform events into signal value changes *\) *)
(*   let compare_ev (t,_) (t',_) = Pervasives.compare t t' in *)
(*   let expand_ev t (id,v) = match v with  *)
(*     None -> [t, (id,Some (Expr.Val_int 1)); t+cfg.vhdl_ev_duration, (id,Some (Expr.Val_int 0))]  (\* event *\) *)
(*   | Some _ -> [t, (id,v)] in *)
(*   let rec expand_stims stims = *)
(*     let rec h acc l = match l with *)
(*       [] -> acc *)
(*     | (t,evs)::rest -> h (acc @ List.flatten (List.map (expand_ev t) evs)) rest in  *)
(*     h [] stims in *)
(*   let merge_stims stims = *)
(*     let rec h acc l = match l, acc with *)
(*       [], _ -> acc *)
(*     | (t,ev)::rest, ((t',evs)::acc') -> if t=t' then h ((t,ev::evs)::acc') rest else h ((t,[ev])::acc) rest *)
(*     | (t,ev)::rest, [] -> h [t,[ev]] rest in *)
(*     List.rev (h [] stims) in *)
(*   expand_stims stimuli |> List.sort compare_ev |> merge_stims  (\* The heavy way.. *\) *)
      
let dump_testbench_impl fname m =
  let oc = open_out fname in
  let open Comp in
  let modname n = String.capitalize_ascii n in
  fprintf oc "library ieee;\n";
  fprintf oc "use ieee.std_logic_1164.all;	   \n";
  fprintf oc "use ieee.numeric_std.all;\n";
  fprintf oc "library %s;\n" cfg.vhdl_support_library;
  fprintf oc "use %s.%s.all;\n" cfg.vhdl_support_library cfg.vhdl_support_package;
  fprintf oc "\n";
  fprintf oc "entity tb is\n";
  fprintf oc "end tb;\n";
  fprintf oc "\n";
  fprintf oc "architecture Bench of tb is\n";
  fprintf oc "\n";
  List.iter (dump_module_intf "component" oc m) m.m_fsms;
  fprintf oc "\n";
  reset_types ();
  (* Signals *)
  List.iter
   (function (id,(ty,_)) ->
     fprintf oc "signal %s: %s;\n" (tb_name id) (string_of_type ty);
     add_type (id, vhdl_type_of ty))
   (m.m_inputs @ m.m_outputs @ m.m_shared);
  fprintf oc "signal %s: std_logic;\n" (tb_name cfg.vhdl_reset_sig);
  if cfg.vhdl_trace then
    List.iter
      (function f -> fprintf oc "  signal %s: integer;\n" (f.f_name ^ "_state"))
      m.m_fsms;  
  fprintf oc "\n";
  fprintf oc "begin\n";
  fprintf oc "\n";
  (* Input generators *)
  List.iter (dump_input_process oc) m.m_inputs;
  fprintf oc "\n";
  (* Instanciated components *)
  List.iteri
    (fun i f ->
      let m = Cmodel.c_model_of_fsm m f in
      let actual_name (id,_) = f.f_l2g id in
      fprintf oc "  U%d: %s port map(%s%s);\n"
        i
        (modname f.f_name)
        (ListExt.to_string tb_name ","
           (List.map actual_name (m.c_inps @  m.c_outps @ m.c_inouts) @ [cfg.vhdl_reset_sig]))
        (if cfg.vhdl_trace then "," ^ f.f_name ^ "_state" else ""))
    m.m_fsms;
  (* Main process *)
  fprintf oc "\n";
  fprintf oc "  process\n";
  fprintf oc "\n";
  fprintf oc "  begin\n";
  fprintf oc "    %s <= '1';\n" cfg.vhdl_reset_sig;
  fprintf oc "    wait for %d %s;\n" cfg.vhdl_reset_duration cfg.vhdl_time_unit;
  fprintf oc "    %s <= '0';\n" cfg.vhdl_reset_sig;
  (* let rst = cfg.vhdl_reset_sig in *)
  (* add_type (rst, Std_logic); *)
  (* let reset_event acc (id,(ty,_)) = match ty with *)
  (*     TyEvent -> (id, Some (Expr.Val_int 0)) :: acc *)
  (*   | _ -> acc in *)
  (* let init_stim = *)
  (*   [0, (rst, Some (Expr.Val_int 1)) :: List.fold_left reset_event [] m.m_inputs; *)
  (*    cfg.vhdl_reset_duration, [rst, Some (Expr.Val_int 0)]] in *)
  (* let stimuli' = mk_events (Stimuli.merge_stimuli [init_stim;stimuli]) in *)
  (* let _ = List.fold_left *)
  (*   (fun t (t',sts) -> *)
  (*     fprintf oc "    wait for %d %s;\n" (t'-t) cfg.vhdl_time_unit; *)
  (*     List.iter (dump_stimulus oc) sts; *)
  (*     t') *)
  (*   0 *)
  (*   stimuli' in *)
  fprintf oc "    wait for %d %s;\n" cfg.vhdl_stop_time cfg.vhdl_time_unit;
  fprintf oc "    wait;\n";
  fprintf oc "\n";
  fprintf oc "  end process;\n";
  fprintf oc "end Bench;\n";
  Logfile.write fname;
  close_out oc

let dump_fsm ?(prefix="") ?(dir="./vhdl") m fsm =
  let prefix = match prefix with "" -> fsm.Fsm.f_name | p -> p in
  let fname = dir ^ "/" ^ prefix ^ ".vhd" in
  let oc = open_out fname in
  fprintf oc "library ieee;\n";
  fprintf oc "use ieee.std_logic_1164.all;\n";
  fprintf oc "use ieee.numeric_std.all;\n";
  fprintf oc "library %s;\n" cfg.vhdl_support_library;
  fprintf oc "use %s.%s.all;\n" cfg.vhdl_support_library cfg.vhdl_support_package;
  fprintf oc "\n";
  dump_module_intf "entity" oc m fsm;
  fprintf oc "\n";
  dump_module_arch oc m fsm;
  Logfile.write fname;
  close_out oc

(* let dump_input ?(prefix="") ?(dir="./vhdl") m ((id,_) as inp) = *)
(*   let prefix = match prefix with "" -> cfg.vhdl_inpmod_prefix ^ id | p -> p in *)
(*   let fname = dir ^ "/" ^ prefix ^ ".vhd" in *)
(*   let oc = open_out fname in *)
(*   fprintf oc "library ieee;\n"; *)
(*   fprintf oc "use ieee.std_logic_1164.all;\n"; *)
(*   fprintf oc "use ieee.numeric_std.all;\n"; *)
(*   fprintf oc "library %s;\n" cfg.vhdl_support_library; *)
(*   fprintf oc "use %s.%s.all;\n" cfg.vhdl_support_library cfg.vhdl_support_package; *)
(*   fprintf oc "\n"; *)
(*   dump_inp_module_intf "entity" oc inp; *)
(*   fprintf oc "\n"; *)
(*   dump_inp_module_arch oc inp; *)
  (* Logfile.write fname; *)
(*   close_out oc *)

let dump_testbench ?(name="") ?(dir="./vhdl") m =
  let prefix = match name with "" -> cfg.vhdl_tb_name | p -> p in
  dump_testbench_impl (dir ^ "/" ^ prefix ^ ".vhd") m

let dump_model ?(dir="./vhdl") m =
  List.iter (dump_fsm ~dir:dir m) m.Comp.m_fsms

(* Dumping Makefile *)

let dump_makefile ?(dir="./vhdl") m =
  let fname = dir ^ "/" ^ "Makefile" in
  let oc = open_out fname in
  let modname suff f = f.f_name ^ suff in
  let open Comp in
  fprintf oc "include %s/etc/Makefile.vhdl\n\n" cfg.vhdl_lib_dir;
  fprintf oc "%s: %s %s.vhd\n"
          cfg.vhdl_tb_name
          (ListExt.to_string (modname ".vhd") " " m.m_fsms)
          cfg.vhdl_tb_name;
  List.iter
    (function f -> fprintf oc "\t$(GHDL) -a $(GHDLOPTS) %s\n" (modname ".vhd" f))
    m.m_fsms;
  fprintf oc "\t$(GHDL) -a $(GHDLOPTS) %s.vhd\n" cfg.vhdl_tb_name;
  fprintf oc "\t$(GHDL) -e $(GHDLOPTS) %s\n" cfg.vhdl_tb_name;
  Logfile.write fname;
  close_out oc

(* Check whether a model can be translated *)

let check_allowed m =
  let open Comp in 
  let is_mono_sync f = match Fsm.input_events_of f with
    | [_] -> ()
    | _ -> Error.not_implemented "Vhdl: FSM with more than one input event" in
  let no_outp_event f = match Fsm.output_events_of f with
    | [] -> ()
    | _ -> Error.not_implemented "Vhdl: FSM with output event(s)" in
  if List.length m.m_fsms > 1 then Error.not_implemented "Vhdl: multi-FSMs model";
  List.iter is_mono_sync m.m_fsms;
  List.iter no_outp_event m.m_fsms
   
