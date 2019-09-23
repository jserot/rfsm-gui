OBELISK=obelisk

DOC=rfsm-gui

SRCS= bnf.tex \
	gui.tex \
	introduction.tex \
	overview.tex \
	syntax.tex \
	rfsm-gui.tex
GEN_SRCS = rfsmc-options.tex # grammar.tex

all: $(DOC).pdf
	cp rfsm-gui.pdf ~/Dev/github.io/rfsm-gui-docs

$(DOC).pdf: $(SRCS) 
	pdflatex $(DOC).tex > pdflatex.log
	pdflatex $(DOC).tex > pdflatex.log

clean:
	\rm -f *.dvi *.log *.rel *.aux *.toc

.PHONY: grammar.tex

gen_tex_option = \
	awk -F ";" '{ printf("%s & %s\\\\\n", $$3, $$6) }' < $(1) | sed 's/_/\\_/g' > $(2)

rfsmc-options.tex: ../../src/compiler/options_spec.txt
	$(call gen_tex_option,$<,$@)

grammar.tex: ../../src/compiler/main_parser.mly
	@read -p "** About to regenerate ./grammar.tex. Are you sure ? " r;\
	if [ $$r = "yes" ]; then (cp ./grammar.tex grammar.sav.tex; $(OBELISK) latex -i -prefix rfsm -o grammar.tex -package grammar-defns $<; echo "** Done. Now diff-edit grammar.sav.tex and grammar.tex (resp. sav/grammar-defns.sty and grammar-defns.sty)  to integrate changes"); fi

realclean: clobber

clobber: clean
	\rm -f $(DOC).pdf *~ 
