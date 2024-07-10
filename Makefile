PC = pandoc
SRC_DIR = src
ITEMS_DIR = items
TEMPLATE = $(SRC_DIR)/template.html
TEMPLATE_WITH_LATEX = $(SRC_DIR)/template-with-katex.html
IDX_TEMPLATE = $(SRC_DIR)/index-template.html

items = $(item8) $(item2) $(item3) $(item4) $(item5) $(item6) $(item7)

item8 = fortran-regular-expression-forgex-v2.0-released.html
item7 = new-light-on-fortran-string-processing-forgex-1st-release.html
item6 = for-numerical-simulations-supported-by-database-in-fortran.html
item5 = accessing-a-database-server-via-fortran-en.html
item4 = postgresql15-on-freebsd13.2-part2.html
item3 = postgresql15-on-freebsd13.2-part1.html
item2 = lets-use-procedure-pointers-in-object-oriented-fortran.html
item1 = how-to-use-coarray-fortran-with-mpi-io.html 

all: index $(items)

index: index.html

index.html: $(SRC_DIR)/index.md $(SRC_DIR)/index-template.html
	$(PC) -f markdown -t html --template=$(SRC_DIR)/index-template.html --toc --no-highlight -V pagetitle="$@" $< > $@


fortran-regular-expression-forgex-v2.0-released.html: $(SRC_DIR)/fortran-regular-expression-forgex-v2.0-released.md
	cat $< > $@.tmp
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight -V pagetitle="$@" --mathjax $@.tmp > $(ITEMS_DIR)/$@
	rm -rf $@.tmp

new-light-on-fortran-string-processing-forgex-1st-release.html: $(SRC_DIR)/new-light-on-fortran-string-processing-forgex-1st-release.md
	cat $< > $@.tmp
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight -V pagetitle="$@" --mathjax $@.tmp > $(ITEMS_DIR)/$@
	rm -rf $@.tmp

for-numerical-simulations-supported-by-database-in-fortran.html: $(SRC_DIR)/for-numerical-simulations-supported-by-database-in-fortran.md
	cat $< > $@.tmp
	$(PC) -f markdown -t html5 --template=$(TEMPLATE_WITH_LATEX) --toc --no-highlight -V pagetitle="$@" --mathjax  $@.tmp > $(ITEMS_DIR)/$@
	rm -rf $@.tmp

accessing-a-database-server-via-fortran-en.html: $(SRC_DIR)/accessing-a-database-server-via-fortran-en.md $(TEMPLATE)
	cat $< > $@.tmp
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight -V pagetitle="$@" --mathjax $@.tmp > $(ITEMS_DIR)/$@
	rm -rf $@.tmp

postgresql15-on-freebsd13.2-part2.html: $(SRC_DIR)/postgresql15-on-freebsd13.2-part2.md $(TEMPLATE)
	cat $< > $@.tmp
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight -V pagetitle="$@" --mathjax $@.tmp > $(ITEMS_DIR)/$@
	rm -rf $@.tmp

postgresql15-on-freebsd13.2-part1.html: $(SRC_DIR)/postgresql15-on-freebsd13.2-part1.md $(TEMPLATE)
	cat $< > $@.tmp
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight -V pagetitle="$@" --mathjax $@.tmp > $(ITEMS_DIR)/$@
	rm -rf $@.tmp
	

lets-use-procedure-pointers-in-object-oriented-fortran.html: $(SRC_DIR)/Lets-Use-Procedure-Pointers-in-Object-oriented-Fortran.md $(TEMPLATE)
	grep -v '^\s*>' $< > $@.tmp
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight -V pagetitle="$@" --mathjax $@.tmp > $(ITEMS_DIR)/$@
	rm -rf $@.tmp

how-to-use-coarray-fortran-with-mpi-io.html: $(SRC_DIR)/how-to-use-coarray-fortran-with-mpi-io.md $(TEMPLATE)
	grep -v '^\s*>' $< > $@.tmp
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight -V pagetitle="$@" --mathjax $@.tmp > $(ITEMS_DIR)/$@
	rm -rf $@.tmp

test.html: $(SRC_DIR)/test.md $(TEMPLATE)
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight --mathjax $< > $(ITEMS_DIR)/$@

clean:
	cd $(ITEMS_DIR)
	rm -rf test.html
	rm -rf how-to-use-coarray-fortran-with-mpi-io.html
