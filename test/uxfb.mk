# Link flags
export LDFLAGS  = -L$(BUILD_DIR) -lgpx

# Default.
.PHONY: all
all: $(OBJS)
	$(CC) -o $(basename $<) $< $(LDFLAGS)

$(BUILD_DIR)/%.$(OBJ_EXT): %.c
	$(CC) -c -o $(BUILD_DIR)/$(@F) $< $(CFLAGS) 