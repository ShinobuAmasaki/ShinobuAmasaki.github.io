PC = pandoc
SRC_DIR = src
TEMPLATE = $(SRC_DIR)/template.html

test.html: $(SRC_DIR)/test.md $(TEMPLATE)
	$(PC) -f markdown -t html --template=$(TEMPLATE) --toc --no-highlight --mathjax $< > $@
