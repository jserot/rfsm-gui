include config
include platform

QMAKE=qmake

.PHONY: build install clean

all: build

build:
#	cat src/gui/builtin_options.txt src/compiler/options_spec.txt > src/gui/options_spec.txt
ifeq ($(PLATFORM), windows)
	make -f Makefile.windows build
endif
ifeq ($(PLATFORM), macos)
	make -f Makefile.macos
endif
ifeq ($(PLATFORM), linux)
	(cd src; $(QMAKE) rfsm.pro; make)
endif

doc: 
ifeq ($(BUILD_DOC),yes)
	(cd doc/um; make)
endif

html:
	pandoc -o CHANGES.html CHANGES.md
	pandoc -o README.html README.md

CHANGES.html: CHANGES.md
	pandoc -o CHANGES.html CHANGES.md
README.html: README.md
	pandoc -o README.html README.md


install:
	mkdir -p $(INSTALL_LIBDIR)
	cp ./platform $(INSTALL_LIBDIR)
	mkdir -p $(INSTALL_BINDIR)
#	cp $(RFSMC) $(RFSMMAKE) $(INSTALL_BINDIR)
	cp $(RFSMC) $(INSTALL_BINDIR)
#	sed -e 's,__LIBDIR__,$(INSTALL_LIBDIR),' ./etc/rfsmmake > $(INSTALL_BINDIR)/rfsmmake
#	chmod a+x $(INSTALL_BINDIR)/rfsmmake
ifeq ($(PLATFORM), macos)
	cp -r src/rfsm.app $(INSTALL_BINDIR)
else
	cp src/rfsm $(INSTALL_BINDIR)/rfsm
endif
ifeq ($(BUILD_DOC),yes)
	mkdir -p $(INSTALL_DOCDIR)
	cp -r doc/um/rfsm-gui.pdf $(INSTALL_DOCDIR)
endif

###### Building the MacOS distribution

macos-dist:
	@echo "** Cleaning"
	make clobber
#	@echo "** Configuring for MacOS distribution"
#	./configure -platform macos -dot "dot" -dotviewer "open -a Graphviz" -vcdviewer "open -a gtkwave" -txtviewer "open"
	make -f Makefile.macos build
	make -f Makefile.macos install
	make -f Makefile.macos installer

###### Building the Windows distribution

WIN_SRC_DIR=~/Desktop/SF1/Qt/rfsm-gui
CURRENT_SRC_DIR=`pwd`
RFSMC_SRC_DIR=`pwd`/../rfsmc

win-pre:
	@echo "** Preparing Windows version.."
	@echo "** Cleaning source directory.."
	make clobber
	@echo "Building documentation"
	(cd doc/um; make)
	@echo "** Copying source tree"
	if [ -d $(WIN_SRC_DIR) ]; then rm -rf $(WIN_SRC_DIR); fi
	cp -r $(CURRENT_SRC_DIR) $(WIN_SRC_DIR)
	mkdir $(WIN_SRC_DIR)/examples
	cp -r $(RFSMC_SRC_DIR)/examples/{single,multi} $(WIN_SRC_DIR)/examples
	@echo "** Done"
	@echo "** Now, make win-{build,install,installer} from Windows"

win-build:
	@echo "******************************************************************************"
	@echo "**** WARNING: this make step must be invoked from a [mingw32(MSYS)] shell ****"
	@echo "******************************************************************************"
	make -f Makefile.windows

win-install:
	make -f Makefile.windows install

win-installer:
	make -f Makefile.windows installer

clean:
	(cd src; make clean)
	(cd doc/um; make clean)
	rm -f doc/lib/*

clobber: clean
	(cd src; make clean)
	(cd doc/um; make clobber)
	rm -f doc/lib/*
	\rm -f src/rfsm.app/Contents/MacOS/rfsm
	\rm -f *~
	\rm -f README.html CHANGES.html

