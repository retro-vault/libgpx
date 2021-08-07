# Virtual paths are all subfolders!
DIRS	=	$(wildcard native/$(PLATFORM)/)
vpath %.c $(DIRS)
vpath %.s $(DIRS)
vpath %.h $(DIRS)

# Source files.
C_SRCS	=	$(wildcard *.c) $(wildcard native/$(PLATFORM)/*.c)
S_SRCS	=	$(wildcard *.s) $(wildcard native/$(PLATFORM)/*.s)
OBJS	=	$(addprefix $(BUILD_DIR)/, \
				$(notdir \
					$(patsubst %.c,%.rel,$(C_SRCS)) \
					$(patsubst %.s,%.rel,$(S_SRCS)) \
				) \
			)
TARGET = libgpx

# Rules.
.PHONY: all
all:	$(BUILD_DIR)/$(TARGET).lib

$(BUILD_DIR)/$(TARGET).lib: $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

$(BUILD_DIR)/%.rel:	%.s
	$(AS) $(ASFLAGS) $(BUILD_DIR)/$(@F) $<

$(BUILD_DIR)/%.rel: %.c
	$(CC) -c -o $(BUILD_DIR)/$(@F) $< $(CFLAGS)

$(BUILD_DIR)/%.rel: %.h