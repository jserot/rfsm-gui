(**********************************************************************)
(*                                                                    *)
(*              This file is part of the RFSM package                 *)
(*                                                                    *)
(*  Copyright (c) 2018-present, Jocelyn SEROT.  All rights reserved.  *)
(*                                                                    *)
(*  This source code is licensed under the license found in the       *)
(*  LICENSE file in the root directory of this source tree.           *)
(*                                                                    *)
(**********************************************************************)

type target = Dot | Sim | CTask | SystemC | Vhdl
                                          
let target = ref None
           
let target_dir = ref "."
let vcd_file = ref "run.vcd"
let print_version = ref false
let do_run = ref false
let dump_model = ref false
let dot_captions = ref true
let dot_fsm_insts = ref false
let dot_fsm_models = ref false

let set_sim () = target := Some Sim
let set_dot () = target := Some Dot
let set_ctask () = target := Some CTask
let set_systemc () = target := Some SystemC
let set_vhdl () = target := Some Vhdl
let set_vcd_file file = vcd_file := file
let set_print_version () = print_version := true
let set_dump_model () = dump_model := true
let set_lib_dir d =
  Systemc.cfg.Systemc.sc_lib_dir <- d;
  Vhdl.cfg.Vhdl.vhdl_lib_dir <- d
let set_target_dir name = target_dir := name

let set_systemc_time_unit u = Systemc.cfg.Systemc.sc_time_unit <- u

let set_vhdl_use_variables () = Vhdl.cfg.Vhdl.vhdl_use_variables <- true
let set_vhdl_time_unit u = Vhdl.cfg.Vhdl.vhdl_time_unit <- u
let set_vhdl_ev_duration d = Vhdl.cfg.Vhdl.vhdl_ev_duration <- d
let set_vhdl_rst_duration d = Vhdl.cfg.Vhdl.vhdl_reset_duration <- d

let set_stop_time d =
  Systemc.cfg.Systemc.sc_stop_time <- d;
  Vhdl.cfg.Vhdl.vhdl_stop_time <- d

let set_trace level = Trace.level := level
let set_sc_trace () = Systemc.cfg.Systemc.sc_trace <- true
let set_vhdl_trace () = Vhdl.cfg.Vhdl.vhdl_trace <- true

let set_dot_no_captions () = dot_captions := false
let set_dot_fsm_insts () = dot_fsm_insts := true
let set_dot_fsm_models () = dot_fsm_models := true
