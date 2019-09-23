# RFSM 

RFSM is an application for describing and simulating StateChart-like state diagrams.
It takes

* a description of a system as a set of StateChart-like state diagrams

* a description of stimuli to be used as input for this system

and generate

* a graphical representation of the system (to be viewed with [Graphviz](http://www.graphviz.org) for example)

* execution traces as `.vcd` files (to be viewed with [Gtkwave](http://gtkwave.sourceforge.net) for example)

Additionnaly, dedicated backends can generate system descriptions in

* `CTask` (a C dialect with primitives for describing tasks and event-based synchronisation)

* `SystemC`

* `VHDL` 

RFSM is actually a graphical front-end to the [rfsmc](https://github.com/jserot/rfsm) compiler.

## Documentation

The project web page is [here](http://dream.ispr-ip.fr/RFSM).

The user manual can be found [here](http://jserot.github.io/rfsm-gui-docs/rfsm-gui.pdf).

Detailed information on the RFSM language can be found on the [rfsmc compiler github
page](https://github.com/jserot/rfsm).


## Installation

### Using binary versions

Prebuilt Windows and MacOS versions can be downloaded
[here](https://github.com/jserot/rfsm-gui/releases) or the [project webpage](http://dream.ispr-ip.fr/RFSM).

### Building from source 

#### Pre-requisites

* [ocaml](http://ocaml.org) (version>=4.08) with latest version of the following [opam](http://opam.ocaml.org) packages installed:
  - [lascar](http://opam.ocaml.org/packages/lascar)
  - [rfsm](http://opam.ocaml.org/packages/rfsm)
* [Qt](http://www.qt.io) (version>=5.8)
* For building the documentation from source: a working `LaTeX` installation (with the `pdftex`
  command)

#### How to build

* Get the source code: `git clone https://github.com/jserot/rfsm-gui`
* `cd rfsm-gui`
* `./configure [options]` (`./configure --help` for the list of options)
* `make`
* `make install` 

If you can't or don't want to build the documentation from source, pass the `--no-doc` option to
`configure`. A pre-built `pdf` version is available [here](http://jserot.github.io/rfsm-gui-docs/rfsm-gui.pdf).

Building on Windows requires (Cygwin)[https://cygwin.com] or (MinGW)[http://www.mingw.org] which
`gcc`, `ocaml` and `opam` installed.
