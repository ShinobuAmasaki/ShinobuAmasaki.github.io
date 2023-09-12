PC = pandoc
SRC_DIR = src
ITEMS_DIR = items
TEMPLATE = $(SRC_DIR)/template.html
IDX_TEMPLATE = $(SRC_DIR)/index-template.html

index: index.html
items: item1 item2 item3

item3: postgresql15-on-freebsd13.2-part1.html
item2: lets-use-procedure-pointers-in-object-oriented-fortran.html
item1: how-to-use-coarray-fortran-with-mpi-io.html 

index.html: $(SRC_DIR)/index.md $(SRC_DIR)/index-template.html
	$(PC) -f markdown -t html --template=$(SRC_DIR)/index-template.html --toc --no-highlight -V pagetitle="$@" $< > $@

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
