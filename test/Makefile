# Object file extenion.
ifeq ($(PLATFORM),uxfb)
export OBJ_EXT  = o
else
export OBJ_EXT  = rel
endif


# Test files to compile.
export C_SRCS   =  $(wildcard *.c)
export OBJS     =  $(addprefix $(BUILD_DIR)/, \
				$(notdir \
					$(patsubst %.c,%.$(OBJ_EXT),$(C_SRCS)) \
				) \
			)

# Configure tools for the target platform.
include $(PLATFORM).mk