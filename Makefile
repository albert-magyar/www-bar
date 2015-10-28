# These prefixes sort the various pages into categories
BIN_DIR ?= output
HDR_DIR ?= templates
SRC_DIR ?= pages
INSTALL_DIR ?= a5.millennium.berkeley.edu:/project/eecs/parlab/www/bar/data

JQUERY_VERSION ?= 1.11.3
SLICK_VERSION ?= 1.5.7
BLOGC_VERSION ?= 0.4

NEWS_DIR ?= $(SRC_DIR)/news
JS_DIR ?= $(SRC_DIR)/js
CSS_DIR ?= $(SRC_DIR)/css
IMG_DIR ?= $(SRC_DIR)/images
PROJECT_DIR ?= $(SRC_DIR)/projects

# These programs are needed to build the website, if you don't have them then
# some will be built automatically, some won't.
BLOGC ?= $(shell which blogc 2> /dev/null)
MENUGEN ?= tools/menugen
RSYNC ?= $(shell which rsync 2> /dev/null)
WGET ?= $(shell which wget 2> /dev/null)

ifeq (,$(wildcard $(BLOGC)))
BLOGC = tools/blogc/build/blogc
endif

# The big list of all targets goes in here
ALL += $(BIN_DIR)/index.html
ALL += $(BIN_DIR)/news.html
ALL += $(BIN_DIR)/projects.html
ALL += $(BIN_DIR)/history.html
ALL += $(BIN_DIR)/publications.html
ALL += $(BIN_DIR)/people.html
ALL += $(BIN_DIR)/menu.js
ALL += $(BIN_DIR)/news/menu.js
ALL += $(BIN_DIR)/projects/menu.js
ALL += $(BIN_DIR)/favicon.ico
ALL += $(BIN_DIR)/js/jquery.min.js
ALL += $(BIN_DIR)/js/slick.min.js
ALL += $(BIN_DIR)/css/slick.css
ALL += $(BIN_DIR)/css/slick-theme.css
ALL += $(BIN_DIR)/fonts/slick.woff
ALL += $(BIN_DIR)/fonts/slick.ttf
ALL += $(BIN_DIR)/fonts/slick.svg
ALL += $(patsubst $(NEWS_DIR)/%.md,$(BIN_DIR)/news/%.html,$(wildcard $(NEWS_DIR)/*.md))
ALL += $(patsubst $(PROJECT_DIR)/%.md,$(BIN_DIR)/projects/%.html,$(wildcard $(PROJECT_DIR)/*.md))
ALL += $(patsubst $(CSS_DIR)/%,$(BIN_DIR)/css/%,$(wildcard $(CSS_DIR)/*.css))
ALL += $(patsubst $(JS_DIR)/%,$(BIN_DIR)/js/%,$(wildcard $(JS_DIR)/*.js))
ALL += $(patsubst $(IMG_DIR)/%,$(BIN_DIR)/images/%,$(wildcard $(IMG_DIR)/*.png))
ALL += $(patsubst $(IMG_DIR)/%,$(BIN_DIR)/images/%,$(wildcard $(IMG_DIR)/*.jpeg))
all: $(ALL)

# These simple targets won't really ever change
.PHONY: clean
clean:
	rm -rf $(BIN_DIR)

.PHONY: install
install:
	$(RSYNC) -av --delete $(BIN_DIR)/ $(INSTALL_DIR)/

# The additional dependencies that are added to some files, which results in
# them showing up inside the generated output file.  Note that there's some
# hackery in here to make sure the ordering is correct everywhere. 
NEWS = $(shell find $(NEWS_DIR) -iname "*.md" | sort --reverse)
$(BIN_DIR)/news.html: $(NEWS)
$(BIN_DIR)/index.html: $(wordlist 1,5,$(NEWS))

PROJECTS = $(shell find $(PROJECT_DIR) -iname "*.md" | sort --reverse)
HISTORY = $(shell find $(PROJECT_DIR) -iname "*.md")
$(BIN_DIR)/projects.html: $(PROJECTS)
$(BIN_DIR)/history.html: $(HISTORY)

# These rules generate pages inside the various sub-directories, and must come
# before the top-level rule below that is capable of matching them all.
$(BIN_DIR)/news/%.html: $(BLOGC) $(SRC_DIR)/news/%.md $(HDR_DIR)/news.html
	mkdir -p $(dir $@)
	$(BLOGC) -o $@ -t $(filter %.html,$^) $(filter %.md,$^)

$(BIN_DIR)/projects/%.html: $(BLOGC) $(SRC_DIR)/projects/%.md $(HDR_DIR)/projects.html
	mkdir -p $(dir $@)
	$(BLOGC) -o $@ -t $(filter %.html,$^) $(filter %.md,$^)

# This rule is used to generate the top-level pages, and must come after all
# the additional dependencies above.
$(BIN_DIR)/%.html: $(BLOGC) $(SRC_DIR)/%.md $(HDR_DIR)/top-level.html 
	mkdir -p $(dir $@)
	$(BLOGC) -DSHOW=$(patsubst %.html,%,$(notdir $@)) -o $@ -t $(filter %.html,$^) -l $(filter %.md,$^)

# The menu is a bit special, it's generated by a special command I use
$(BIN_DIR)/menu.js: $(MENUGEN) $(patsubst $(BIN_DIR)/%.html,$(SRC_DIR)/%.md,$(filter %.html,$(ALL)))
	mkdir -p $(dir $@)
	$(MENUGEN) -o $@ -p . $(filter %.md,$^)

$(BIN_DIR)/%/menu.js: $(MENUGEN) $(patsubst $(BIN_DIR)/%.html,$(SRC_DIR)/%.md,$(filter %.html,$(ALL)))
	mkdir -p $(dir $@)
	$(MENUGEN) -o $@ -p .. $(filter %.md,$^)

# Many files are just directly copied over from the from the source directory.
$(BIN_DIR)/css/%.css: $(CSS_DIR)/%.css
	mkdir -p $(dir $@)
	cp -L $< $@

$(BIN_DIR)/js/%.js: $(JS_DIR)/%.js
	mkdir -p $(dir $@)
	cp -L $< $@

$(BIN_DIR)/images/%: $(IMG_DIR)/%
	mkdir -p $(dir $@)
	cp -L $< $@

$(BIN_DIR)/favicon.ico: $(IMG_DIR)/favicon.ico
	mkdir -p $(dir $@)
	cp -L $< $@

# Download javascript from the internet
$(BIN_DIR)/js/jquery.min.js:
	mkdir -p $(dir $@)
	$(WGET) http://code.jquery.com/jquery-$(JQUERY_VERSION).min.js -O $@

$(BIN_DIR)/js/slick.min.js:
	mkdir -p $(dir $@)
	$(WGET) http://cdn.jsdelivr.net/jquery.slick/$(SLICK_VERSION)/slick.min.js -O $@

$(BIN_DIR)/css/slick%:
	mkdir -p $(dir $@)
	$(WGET) http://cdn.jsdelivr.net/jquery.slick/$(SLICK_VERSION)/$(notdir $@) -O $@

$(BIN_DIR)/fonts/slick%:
	mkdir -p $(dir $@)
	$(WGET) http://cdn.jsdelivr.net/jquery.slick/$(SLICK_VERSION)/fonts/$(notdir $@) -O $@

# Some things need to be linked around so they can be used in all the subdirs
LINK_DIRS += $(BIN_DIR)/news/css
LINK_DIRS += $(BIN_DIR)/news/js
LINK_DIRS += $(BIN_DIR)/news/images
LINK_DIRS += $(BIN_DIR)/projects/css
LINK_DIRS += $(BIN_DIR)/projects/js
LINK_DIRS += $(BIN_DIR)/projects/images
all: $(LINK_DIRS)
$(LINK_DIRS):
	mkdir -p $(dir $@)
	rm -f $@
	ln -s ../$(notdir $@) $@

# Build tools that don't exist on this machine
tools/blogc/build/blogc: tools/blogc/build/Makefile
	$(MAKE) -C $(dir $@) $(notdir $@)

tools/blogc/build/Makefile: tools/blogc/configure
	mkdir -p $(dir $@)
	cd $(dir $@); ../configure

tools/blogc/configure: tools/blogc/autogen.sh
	cd $(dir $@) && ./autogen.sh

tools/blogc/autogen.sh: tools/blogc-$(BLOGC_VERSION).tar.gz $(wildcard tools/blogc-*.patch)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	tar -C $(dir $@) -xf $(filter %.tar.gz,$^) --strip-components=1
	cat $(filter %.patch,$^) | patch -d $(dir $@) -p1 -t
	touch $@

tools/blogc-$(BLOGC_VERSION).tar.gz:
	$(WGET) https://github.com/blogc/blogc/archive/v0.4.tar.gz -O $@

.PHONY: clean-blogc
clean: clean-blogc
clean-blogc:
	rm -rf tools/blogc-$(BLOGC_VERSION).tar.gz
	rm -rf tools/blogc
