PC = pandoc
SRC_DIR = src
ITEMS_DIR = items
TEMPLATE = $(SRC_DIR)/template.html

test.html: $(SRC_DIR)/test.md $(TEMPLATE)
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight --mathjax $< > $(ITEMS_DIR)/$@

how-to-use-coarray-fortran-with-mpi-io.html: $(SRC_DIR)/how-to-use-coarray-fortran-with-mpi-io.md $(TEMPLATE)
	grep -v '^\s*>' $< > $@.tmp
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight -V pagetitle="$@" --mathjax $@.tmp > $(ITEMS_DIR)/$@
	rm -rf $@.tmp

clean:
	cd $(ITEMS_DIR)
	rm -rf test.html
	rm -rf how-to-use-coarray-fortran-with-mpi-io.html
