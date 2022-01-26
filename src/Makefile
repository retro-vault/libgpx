# Virtual paths are all subfolders!
DIRS      =  $(wildcard native/$(PLATFORM)/)
vpath %.c $(DIRS)
vpath %.s $(DIRS)
vpath %.h $(DIRS)

# Source files.
C_SRCS   =  $(wildcard *.c) $(wildcard native/$(PLATFORM)/*.c)
S_SRCS   =  $(wildcard *.s) $(wildcard native/$(PLATFORM)/*.s)
OBJS     =  $(addprefix $(BUILD_DIR)/, \
				$(notdir \
					$(patsubst %.c,%.$(OBJ_EXT),$(C_SRCS)) \
					$(patsubst %.s,%.$(OBJ_EXT),$(S_SRCS)) \
				) \
			)
TARGET	 = libgpx

# Default.
.PHONY: all
all: $(BUILD_DIR)/$(TARGET).$(LIB_EXT)

# Common rules for Z80.
$(BUILD_DIR)/$(TARGET).$(LIB_EXT): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

$(BUILD_DIR)/%.$(OBJ_EXT):	%.s
	$(AS) $(ASFLAGS) $(BUILD_DIR)/$(@F) $<

$(BUILD_DIR)/%.$(OBJ_EXT): %.c
	$(CC) -c -o $(BUILD_DIR)/$(@F) $< $(CFLAGS)

$(BUILD_DIR)/%.$(OBJ_EXT): %.h