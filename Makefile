# We only allow compilation on linux!
ifneq ($(shell uname), Linux)
$(error OS must be Linux!)
endif

# Check if all required tools are on the system.
REQUIRED = sdcc sdar sdasz80
K := $(foreach exec,$(REQUIRED),\
    $(if $(shell which $(exec)),,$(error "$(exec) not found. Please install or add to path.")))


# Configure tools for the target platform.
ifeq ($(PLATFORM),partner)
export CC		=	sdcc
export CFLAGS	=	--std-c11 -mz80 -I. $(addprefix -I,$(INC_DIR)) --no-std-crt0 --nostdinc --nostdlib --debug -D PLATFORM=$(PLATFORM)
export AS		=	sdasz80
export ASFLAGS	=	-xlos -g
export AR		=	sdar
export ARFLAGS	=	-rc
else ifeq ($(PLATFORM),zxspec48)
export CC		=	sdcc
export CFLAGS	=	--std-c11 -mz80 -I. $(addprefix -I,$(INC_DIR)) --no-std-crt0 --nostdinc --nostdlib --debug -D PLATFORM=$(PLATFORM)
export AS		=	sdasz80
export ASFLAGS	=	-xlos -g
export AR		=	sdar
export ARFLAGS	=	-rc
else # Default platform for this branch is uxfb
export PLATFORM =   pixie
export CC		=	gcc
export CFLAGS	=	-Wall -Wextra -std=c99 -g $(addprefix -I,$(INC_DIR))
export AS		=	as
export ASFLAGS	=	
export AR		=	ar
export ARFLAGS	=	-crs
endif


# Platform file extenions.
ifeq ($(PLATFORM),pixie)
export OBJ_EXT = o
export LIB_EXT = a
export EXE_EXT = out
else
export OBJ_EXT = rel
export LIB_EXT = lib
export EXE_EXT = ihx
endif

# Other extensions...
export DAT_EXT = dat
export GPY_EXT = g
export FNT_EXT = f


# Global settings: folders.
export ROOT			=	$(realpath .)
export BUILD_DIR	=	$(ROOT)/build
export BIN_DIR		=	$(ROOT)/bin
export INC_DIR		=	$(ROOT)/include $(ROOT)/src $(ROOT)/src/native


# Subfolders for make.
SUBDIRS 			=	src $(LAB)


# Default target
.PHONY: all
all: $(BUILD_DIR) $(SUBDIRS)
	cp $(BUILD_DIR)/*.$(LIB_EXT) $(BIN_DIR) 2>/dev/null || :
	cp $(BUILD_DIR)/*.$(GPY_EXT) $(BIN_DIR) 2>/dev/null || :
	cp $(BUILD_DIR)/*.$(FNT_EXT) $(BIN_DIR) 2>/dev/null || :
	cp $(BUILD_DIR)/*.$(DAT_EXT) $(BIN_DIR) 2>/dev/null || :
	find $(BUILD_DIR) -perm /a+x -exec cp {} $(BIN_DIR) \; 2>/dev/null || :



.PHONY: $(BUILD_DIR)
$(BUILD_DIR):
	# Create build dir.
	mkdir -p $(BUILD_DIR)
	# Remove bin dir (we are going to write again).
	rm -f -r $(BIN_DIR)
	# And re-create!
	mkdir -p $(BIN_DIR)

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@
	
.PHONY: clean
clean:
	rm -f -r $(BUILD_DIR)
	rm -f -r $(BIN_DIR)