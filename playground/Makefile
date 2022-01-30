# Test files to compile.
export C_SRCS   =   $(wildcard *.c)
export OBJS     =   $(addprefix $(BUILD_DIR)/, \
                        $(notdir \
                        $(patsubst %.c,%.$(OBJ_EXT),$(C_SRCS)) \
                      ) \
                    )

# Link flags
export LDFLAGS  = -L$(BUILD_DIR) -lgpx

# Default.
.PHONY: all
all: $(OBJS)
	$(CC) -o $(basename $<) $< $(LDFLAGS)

$(BUILD_DIR)/%.$(OBJ_EXT): %.c
	$(CC) -c -o $(BUILD_DIR)/$(@F) $< $(CFLAGS) 