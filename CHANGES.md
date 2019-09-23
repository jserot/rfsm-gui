# Changes

# 1.6.0 (Sep 23, 2019)
* The application is now only a GUI to the `rfsmc` compiler (which is distributed as a separate
  `opam` package). For convenience, the, distributed MacOS and Windows
  installers include pre-built binaries of the compiler)
* Building from sources under Linux is now supported (tested under LinuxMint19)

# 1.5 (May 30, 2019)
* New syntax for FSM models. Transitions are now written:
     `| src_state -> dst_state ON ev [WHEN guards] [WITH actions]`
     `| -> init_state [WITH actions]`
* New syntax for comments. Now start with `--` (like in VHDL)
* The old syntax is still supported by invoking the compiler with the `-old_syntax` option
* The option `-transl_syntax` can be used to convert source files from old to new syntax
* Updated the user manual with new syntax
* The `-main` option can now also be used to change the name of the top level `.dot` file and the
  generated `.vcd` file
* Removed option `-vcd`
* The name of the testbench (resp. toplevel) modules generated by the VHDL backend is now `main_tb`
  (resp. `main_top`); the `main` prefix can be changed with the `-main` option.
* `rfsmmake` utility for automatic building of top-level `Makefile` from `.pro` file (see Sec. 3.6
  of User Manual)
* Option `-vhdl_dump_ghw` to force GHDL dumping in `.ghw` format instead of `.vcd` (useful for
  displaying values with record type for ex.)
* The `configure` script now writes file a `lib/etc/platform` containing platform-specific
  definitions to be used in generated Makefiles
* Source code for all examples rewritten as FSM model(s) + testbench + `.pro` file
* Revamped GUI with support for projects

# 1.4 (Mar 9, 2019)
* Major code recrafting (lib and compiler)
* Fixed several bugs in scripts/Makefiles when building from sources on Linux platforms
* Added options `--no-libs` and `--no-doc` to `configure` script when building from sources

# 1.3 (Jan 10, 2019)
* Declarations (types, constants, fsm models, etc) can now appear in any order in source file(s)
* The `rfsmc` compiler now accepts a list of `.fsm files` (to improve source level reuse)
* Support for group declarations (ex: `vars i,j: int` or `output o1,o2,o3: bool`)
* Support for enum and record types (see `examples/single/rpcalc` for ex)
* Support for char type (see `examples/single/rle` for ex)
* Updated documentation

# 1.2 (Nov 5, 2018)
* Size and range annotations for int type (ex: `int<8>` and `int<0:255>`)
* Bitwise and shift operators for int values (see `examples/single/{r,t}xd` for ex.)
* Bit range expressions for ints (ex: "v`2`", "v`6:2`") (see `examples/single/bcd` for ex.)
* Support for global constants 
* Testbenches generated by the SystemC and VHDL backend now use a 0.5 duty cycle clock
* VHDL backend now always generate a `Top` module encapsulating the DUT
* Minimal support for multi-FSMs models with shared variable in the VHDL backend
* New examples: `single/{rxd,txd,bcd,rpcalc,rle}` and `multi/rxtx`
* Updated documentation

# 1.1 (Jul 24, 2018)
    * Support for float values (see `examples/single/heron/v1`)
    * Changed syntax for integer range (`int<lo:hi>` instead of `int<lo..hi>`)
    * Support for global functions (see `examples/single/heron/v2`)
    * Support for (1D) array type (see `examples/single/fir/v2`)
    * Bug fix for negative constants in parser
    * Boolean constants are now denoted (and written) 0 (resp. 1) 
    * Boolean type is now translated as `std_logic` in VHDL (unless option `-vhld_bool_as_bool` is asserted)
    * With option `-vhdl_numeric_std`, ranged integers are translated as `unsigned` and `signed` in VHDL 
    * The simulator does not stop when encountering an initialized value but propagates it

# 1.0 (Feb 25, 2018)
    * First public version