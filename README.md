RFSM 
====

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

DOCUMENTATION
-------------

The project web page is [here](http://dream.ispr-ip.fr/RFSM).

The user manual can be found [here](http://jserot.github.io/rfsm-gui-docs/rfsm-gui.pdf).

Detailed information on the RFSM language can be found on the [rfsmc compiler github
page](https://github.com/jserot/rfsm).


INSTALLATION
------------

Prebuilt Windows and MacOS versions can be downloaded
[here](https://github.com/jserot/rfsm-gui/releases) or the [project webpage](http://dream.ispr-ip.fr/RFSM).

Source code is available via by simply cloning this sub-tree: `git clone
https://github.com/jserot/rfsm-gui`. Building the application from source requires:
 * an ocaml compiler (>=4.06) with the following OPAM packages installed:
  - ocamlgraph
  - menhir
  - lascar (>=0.6)
  - rfsm (>=1.6)
 * a working Qt (>=5.0) installation
  
