include config

QMAKE_MACOS = /Developer/Qt5.2.1/5.2.1/clang_64/bin/qmake 
QMAKE_WIN = C:/Qt/Qt5.8.0/5.8/mingw53_32/bin/qmake.exe
MAKE_WIN = C:/Qt/Qt5.8.0/Tools/mingw530_32/bin/mingw32-make
QMAKE_UNIX=qmake

.PHONY: lib compiler gui clean test doc install dist opam opam-doc

all: build

build:
#	cat src/gui/builtin_options.txt src/compiler/options_spec.txt > src/gui/options_spec.txt
ifeq ($(PLATFORM), win32)
	(cd src; $(QMAKE_WIN) -spec win32-g++ rfsm.pro; $(MAKE_WIN))
endif
ifeq ($(PLATFORM), macos)
	(cd src; $(QMAKE_MACOS) -spec macx-clang CONFIG+=x86_64 rfsm.pro; make)
endif
ifeq ($(PLATFORM), unix)
	(cd src; $(QMAKE_UNIX) rfsm.pro; make)
endif

doc: 
ifeq ($(BUILD_DOC),yes)
	(cd doc/um; make)
	pandoc -o CHANGES.html CHANGES.md
	pandoc -o README.html README.md
endif

CHANGES.txt: CHANGES.md
	pandoc -o CHANGES.txt CHANGES.md
README.txt: README.md
	pandoc -o README.txt README.md
CHANGES.html: CHANGES.md
	pandoc -o CHANGES.html CHANGES.md
README.html: README.md
	pandoc -o README.html README.md



RFSMC=$(OPAM_SWITCH_PREFIX)/bin/rfsmc
RFSMMAKE=$(OPAM_SWITCH_PREFIX)/bin/rfsmmake
RFSMLIB=$(OPAM_SWITCH_PREFIX)/share/rfsm

install:
	mkdir -p $(INSTALL_LIBDIR)
	cp -r etc/templates $(INSTALL_LIBDIR)
	cp ./platform $(INSTALL_LIBDIR)
ifeq ($(BUILD_SYSC_LIB),yes)
	mkdir -p $(INSTALL_LIBDIR)/systemc
	cp $(RFSMLIB)/lib/systemc/*.{cpp,h} $(INSTALL_LIBDIR)/systemc
endif
ifeq ($(BUILD_VHDL_LIB),yes)
	mkdir -p $(INSTALL_LIBDIR)/vhdl
	cp $(RFSMLIB)/lib/vhdl/*.vhd $(INSTALL_LIBDIR)/vhdl
endif
	mkdir -p $(INSTALL_BINDIR)
	cp $(RFSMC) $(RFSMMAKE) $(INSTALL_BINDIR)
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

SRCTMPDIR=/tmp
SRCDISTNAME=rfsm-gui-source
SRCDISTDIR=$(SRCTMPDIR)/$(SRCDISTNAME)
EXCLUDES=--exclude .git --exclude .gitignore --exclude .DS_Store
SRCTARBALL=$(SRCDISTNAME).tar
RFSMCDIR=../rfsmc

source-dist: 
	@echo "** Cleaning"
	make clobber
	@echo "** Creating $(SRCDISTDIR)"
	rm -rf $(SRCDISTDIR)
	mkdir -p $(SRCDISTDIR)
	@echo "** Copying files"
	cp -r src $(SRCDISTDIR)
	cp -r doc $(SRCDISTDIR)
	rsync --quiet -avz --exclude dune --exclude bin --exclude emacs --exclude=*~ $(RFSMCDIR)/etc $(SRCDISTDIR)
	rsync --quiet -avz --exclude=do_test* $(RFSMCDIR)/examples $(SRCDISTDIR)
# cp -r $(RFSMCDIR)/etc $(SRCDISTDIR)
# mkdir -p $(SRCDISTDIR)/examples
# cp -r $(RFSMCDIR)/examples/{single,multi,Makefile} $(SRCDISTDIR)/examples
	cp configure CHANGES.md README.md KNOWN-BUGS LICENSE VERSION INSTALL Makefile $(SRCDISTDIR)
	@echo "** Creating archive $(SRCDISTNAME).tar.gz"
	(cd $(SRCTMPDIR); tar -zcf $(SRCTARBALL).gz $(SRCDISTNAME))

MACOS_DIST=/tmp/rfsm

macos-dist:
	@echo "** Cleaning"
	make clobber
	@echo "** Configuring for MacOS distribution"
	./configure -platform macos -dot "dot" -dotviewer "open -a Graphviz" -vcdviewer "open -a gtkwave" -txtviewer "open"
	@echo "** Building"
	(cd src; make)
	make doc
	make macos-install
	make macos-installer

macos-install: CHANGES.txt README.txt
	@echo "** Installing in $(MACOS_DIST)"
	rm -rf $(MACOS_DIST)
	mkdir $(MACOS_DIST)
	cp -r src/rfsm.app $(MACOS_DIST)/Rfsm.app
	cp $(RFSMC) $(MACOS_DIST)/Rfsm.app/Contents/MacOS/rfsmc
	cp $(RFSMMAKE) $(MACOS_DIST)/Rfsm.app/Contents/MacOS/rfsmmake
	cp ./dist/macos/rfsm.ini $(MACOS_DIST)/Rfsm.app/Contents/MacOS
	cp ./dist/macos/INSTALL $(MACOS_DIST)/INSTALL
	mkdir $(MACOS_DIST)/doc
#	cp -r doc/lib $(MACOS_DIST)/doc
	cp  doc/um/rfsm-gui.pdf $(MACOS_DIST)/doc/rfsm-manual.pdf
	mkdir $(MACOS_DIST)/examples
	mkdir $(MACOS_DIST)/examples/{single,multi}
	cp -r examples/single $(MACOS_DIST)/examples
	cp -r examples/multi $(MACOS_DIST)/examples
	cp {CHANGES.txt,KNOWN-BUGS,LICENSE,README.txt} $(MACOS_DIST)

RFSM_VOLUME=Rfsm-$(VERSION)

macos-installer:
	@echo "** Creating disk image"
	rm -f /tmp/Rfsm.dmg
	hdiutil create -size 64m -fs HFS+ -volname "$(RFSM_VOLUME)" /tmp/Rfsm.dmg
	hdiutil attach /tmp/Rfsm.dmg
	cp -r $(MACOS_DIST)/Rfsm.app /Volumes/$(RFSM_VOLUME)
	ln -s /Applications /Volumes/$(RFSM_VOLUME)/Applications
	cp -r $(MACOS_DIST)/examples /Volumes/$(RFSM_VOLUME)/Examples
	cp -r $(MACOS_DIST)/doc /Volumes/$(RFSM_VOLUME)/Documentation
	cp $(MACOS_DIST)/{CHANGES.txt,KNOWN-BUGS,LICENSE,README.txt,INSTALL} /Volumes/$(RFSM_VOLUME)
	hdiutil detach /Volumes/$(RFSM_VOLUME)
	hdiutil convert /tmp/Rfsm.dmg -format UDZO -o /tmp/Rfsm_ro.dmg
	mv /tmp/Rfsm_ro.dmg /tmp/Rfsm.dmg
	@echo "** Done. Disk image is /tmp/Rfsm.dmg"

WIN_SRC_DIR=~/Desktop/SF1/Caml

win32-pre:
	@echo "** Preparing Windows version.."
	@echo "** Cleaning source directory.."
	make clobber
	@echo "Building documentation"
	(cd doc/um; make; cp rfsm.pdf ..)
	@echo "** Copying source tree"
	if [ -d $(WIN_SRC_DIR)/rfsm ]; then rm -rf $(WIN_SRC_DIR)/rfsm.bak; mv $(WIN_SRC_DIR)/rfsm $(WIN_SRC_DIR)/rfsm.bak; fi
	(cd ..; cp -r working $(WIN_SRC_DIR)/rfsm)
	@echo "** Done"
	@echo "** Now, make win32-{gui,compiler} from Windows"

win32-build:
	@echo "******************************************************************************"
	@echo "**** WARNING: this make step must be invoked from a [mingw32(MSYS)] shell ****"
	@echo "******************************************************************************"
	./configure -platform win32 -dot "/C/Program Files/Graphviz/bin/dot.exe" -dotviewer "/C/Program Files/Graphviz/bin/dotty.exe" -vcdviewer "/C/Program Files/gtkwave/bin/gtkwave.exe"
	@echo "** Building GUI"
	make build
	@echo "** Done"

WIN_INSTALL_DIR=./build

win32-install:
	@echo "** Installing in $(WIN_INSTALL_DIR)"
	rm -rf $(WIN_INSTALL_DIR)
	mkdir $(WIN_INSTALL_DIR)
	cp ./src/gui/release/rfsm.exe $(WIN_INSTALL_DIR)
	mkdir $(WIN_INSTALL_DIR)/bin
	cp ./src/compiler/_build/main.native $(WIN_INSTALL_DIR)/bin/rfsmc.exe
	cp ../caph/dlls/{Qt5Core,Qt5Gui,Qt5Widgets,libgcc_s_dw2-1,libstdc++-6,libwinpthread-1}.dll $(WIN_INSTALL_DIR)
	mkdir $(WIN_INSTALL_DIR)/platforms
	cp ../caph/dlls/qwindows.dll $(WIN_INSTALL_DIR)/platforms
	cp {CHANGES.txt,KNOWN-BUGS,LICENSE,README.txt} $(WIN_INSTALL_DIR)
	cp ./dist/windows/FIRST.TXT $(WIN_INSTALL_DIR)
	cp ./dist/windows/icons/*.{bmp,ico} $(WIN_INSTALL_DIR)
	mkdir $(WIN_INSTALL_DIR)/doc
	cp  doc/rfsm.pdf $(WIN_INSTALL_DIR)/doc
	mkdir $(WIN_INSTALL_DIR)/examples
	mkdir $(WIN_INSTALL_DIR)/examples/{single,multi}
	cp -r examples/single $(WIN_INSTALL_DIR)/examples
	cp -r examples/multi $(WIN_INSTALL_DIR)/examples
	@echo "Done"

win32-installer:
	@echo "** Building self-installer"
	/C/Program\ Files/Inno\ Setup\ 5/iscc ./dist/windows/RfsmSetup.iss

# Targets for building and deploying distribution

# TMPDIR=/tmp
# DISTNAME=rfsm
# DISTDIR=$(TMPDIR)/rfsm
# EXCLUDES=--exclude=*~ --exclude .git --exclude .gitignore --exclude .DS_Store 
# TARBALL=$(DISTNAME).tar
# 
# opam-dist: 
# 	@make -f Makefile clean
# 	@rm -rf $(DISTDIR)
# 	@mkdir $(DISTDIR)
# 	@echo "** Copying files into $(DISTDIR)"
# 	(rsync --quiet -avz $(EXCLUDES) . $(DISTDIR))
# 	@ echo "** Creating tarball"
# 	@(cd $(TMPDIR); tar cf $(TARBALL) $(DISTNAME); gzip -f $(TARBALL))
# 	@ echo "** File $(TMPDIR)/$(TARBALL).gz is ready."
# 	echo "checksum: \""`md5 -q $(TMPDIR)/$(TARBALL).gz`"\""

clean:
	(cd src; make clean)
	(cd doc/um; make clean)
	rm -f doc/lib/*

clobber: clean
	(cd src; make clean)
	(cd doc/um; make clobber)
	rm -f doc/lib/*
	\rm -f src/gui/rfsm.app/Contents/MacOS/rfsm
	\rm -f *~

