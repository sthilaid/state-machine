## utility
add-presufix = $(foreach f, $(3), $(1)$(f)$(2))

define define-dependency
DEPENDENCIES += $(1)
$(addprefix $$(SRC_PATH)/,$(2)) : setup-$(1)
setup-$(1):
	 mkdir -p $$(EXTERNAL_LIBS)
 ifeq "$$(wildcard $$(EXTERNAL_LIBS)/$(1))" ""
	 cd $$(EXTERNAL_LIBS) && git clone $$($(1)-PATH)
 endif
	 cd $$(EXTERNAL_LIBS)/$(1) && git pull
	 rsync -c $$(EXTERNAL_LIBS)/$(1)/src/* $$(SRC_PATH)/
endef

## project paths
PREFIX=.
SRC_PATH=src
TEST_PATH=tests
INCLUDE_PATH=$(PREFIX)/include
LIB_PATH=$(PREFIX)/lib
EXTERNAL_LIBS=$(PREFIX)/external-libs

## compilers
GSI=gsi -:dar
GSC=gsc -debug

## project files
INCLUDE_FILES=scm-lib_.scm class.scm class_.scm state-machine.scm
LIB_FILES=scm-lib.o1
TEST_INCLUDE_FILES=$(addprefix $(INCLUDE_PATH)/, $(INCLUDE_FILES))
TEST_RUN_FILES=$(addprefix $(LIB_PATH)/, $(LIB_FILES)) \
               $(TEST_PATH)/test.o1 \
	             $(TEST_PATH)/state-machine-tests.o1

## Some scheme libraries git repos
export scm-lib-PATH=git://github.com/sthilaid/scm-lib.git
export class-PATH=git://github.com/sthilaid/class.git

all: prefix include lib

prefix:
ifneq "$(PREFIX)" "."
	mkdir -p $(PREFIX)
endif

include: $(foreach f,$(INCLUDE_FILES),$(INCLUDE_PATH)/$(f))
$(INCLUDE_PATH)/%.scm: $(SRC_PATH)/%.scm
	mkdir -p $(INCLUDE_PATH)
	cp $< $@

lib: $(foreach f,$(LIB	_FILES),$(LIB_PATH)/$(f))
$(LIB_PATH)/%.o1: $(SRC_PATH)/%.scm
	mkdir -p $(LIB_PATH)
	$(GSC) -cc-options "$(INCLUDE_OPTIONS)" -ld-options "$(LD_OPTIONS)" -o $@ $<

test: $(TEST_INCLUDE_FILES) $(TEST_RUN_FILES)
	$(GSI) $(TEST_RUN_FILES) -e "(run-tests)"

$(TEST_PATH)/%.o1: $(TEST_PATH)/%.scm $(TEST_INCLUDE_FILES)
	$(GSC) -o $@ $<


### External Scheme library dependencies only used if not developping localy
$(eval $(call define-dependency,scm-lib,scm-lib.scm scm-lib_.scm))
$(eval $(call define-dependency,class,class.scm class_.scm))

clean:
	rm -rf generated $(INCLUDE_PATH) $(LIB_PATH) $(EXTERNAL_LIBS) 