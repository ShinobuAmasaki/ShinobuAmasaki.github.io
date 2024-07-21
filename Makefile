ifeq ($(OS),Windows_NT)
	RM = pwsh.exe -Command Remove-Item
	RM_POST = -Force -Recurse
else
	RM = rm -rf
endif

PC = pandoc
SRC_DIR = src
ITEMS_DIR = items
TEMPLATE = $(SRC_DIR)/templates/template.html
TEMPLATE_KATEX = $(SRC_DIR)/templates/template-with-katex.html
MD_FILES = $(wildcard $(SRC_DIR)/items/*.md)
MD_FILES_KATEX = $(wildcard $(SRC_DIR)/items/with-katex/*.md)

# Define the list of HTML files to be generated from markdown files
ITEMS = $(patsubst $(SRC_DIR)/items/%.md, $(ITEMS_DIR)/%.html, $(MD_FILES))
WITH_KATEX = $(patsubst $(SRC_DIR)/items/with-katex/%.md, $(ITEMS_DIR)/%.html, $(MD_FILES_KATEX))

all: index.html $(ITEMS) $(WITH_KATEX)

index.html: $(SRC_DIR)/index.md $(SRC_DIR)/templates/index-template.html
	$(PC) -f markdown -t html --template=$(SRC_DIR)/templates/index-template.html --eol=lf --toc --no-highlight -V pagetitle="$@" $< > $@

$(ITEMS_DIR)/%.html: $(SRC_DIR)/items/with-katex/%.md $(TEMPLATE_KATEX)
	$(PC) -f markdown -t html5 --template=$(TEMPLATE_KATEX) --eol=lf --toc --no-highlight -V pagetitle="$@" --mathjax $< > $@

$(ITEMS_DIR)/%.html: $(SRC_DIR)/items/%.md $(TEMPLATE)
	$(PC) -f markdown -t html --template=$(TEMPLATE) --eol=lf --toc --no-highlight -V pagetitle="$@" --mathjax $< > $@


clean:
ifeq ($(OS),Windows_NT)
	$(RM) .\$(ITEMS_DIR)\*.html $(RM_POST)
else
	$(RM) $(ITEMS_DIR)/*.html
endif