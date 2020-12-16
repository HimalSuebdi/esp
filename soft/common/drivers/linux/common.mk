ifeq ("$(CPU_ARCH)", "ariane")
CROSS_COMPILE ?= riscv64-unknown-linux-gnu-
ARCH ?= riscv
else # ifeq ("$(CPU_ARCH)", "leon3")
CROSS_COMPILE ?= sparc-linux-
ARCH ?= sparc
# uclibc does not have sinf()
CFLAGS += -fno-builtin-cos -fno-builtin-sin
endif

SRCS := $(wildcard *.c)
HEADERS := $(wildcard *.h) $(wildcard $(DRIVERS)/include/*.h)
HEADERS += $(wildcard $(DRIVERS)/../common/include/*.h) $(wildcard ../include/*.h)
ifeq ($(APPNAME),)
EXES := $(SRCS:.c=.exe)
EXES := $(addprefix  $(BUILD_PATH)/, $(EXES))
else
SRCS := $(filter-out $(APPNAME).c, $(SRCS))
OBJS := $(SRCS:.c=.o)
OBJS := $(addprefix  $(BUILD_PATH)/, $(OBJS))
SRC := $(APPNAME).c
EXE := $(BUILD_PATH)/$(APPNAME).exe
endif

CFLAGS += $(EXTRA_CFLAGS)
CFLAGS += -O3
CFLAGS += -Wall
CFLAGS += -I$(DRIVERS)/include -I$(DRIVERS)/../common/include -I../include
CFLAGS += -L$(BUILD_PATH)/../../../contig_alloc -L$(BUILD_PATH)/../../../test
CFLAGS += -L$(BUILD_PATH)/../../../libesp -L$(BUILD_PATH)/../../../utils/linux
LDFLAGS += -lm -lrt -lpthread -lesp -ltest -lcontig -lutils

CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)$(LD)

all: $(OBJS) $(EXES) $(EXE) $(BINS) $(BIN)

ifneq ($(APPNAME),)
$(BUILD_PATH)/%.o: %.c $(HEADERS)
	CROSS_COMPILE=$(CROSS_COMPILE) DRIVERS=$(DRIVERS) $(MAKE) -C $(BUILD_PATH)/../../../contig_alloc/ libcontig.a
	CROSS_COMPILE=$(CROSS_COMPILE) BUILD_PATH=$(BUILD_PATH)/../../../test $(MAKE) -C $(DRIVERS)/test
	CROSS_COMPILE=$(CROSS_COMPILE) BUILD_PATH=$(BUILD_PATH)/../../../libesp $(MAKE) -C $(DRIVERS)/libesp
	CROSS_COMPILE=$(CROSS_COMPILE) BUILD_PATH=$(BUILD_PATH)/../../../utils/linux $(MAKE) -C $(DRIVERS)/utils
	$(CC) $(CFLAGS) -c $< -o $@ $(LDFLAGS)
endif

$(BUILD_PATH)/%.exe: %.c $(OBJS) $(HEADERS)
	CROSS_COMPILE=$(CROSS_COMPILE) DRIVERS=$(DRIVERS) $(MAKE) -C $(BUILD_PATH)/../../../contig_alloc/ libcontig.a
	CROSS_COMPILE=$(CROSS_COMPILE) BUILD_PATH=$(BUILD_PATH)/../../../test $(MAKE) -C $(DRIVERS)/test
	CROSS_COMPILE=$(CROSS_COMPILE) BUILD_PATH=$(BUILD_PATH)/../../../libesp $(MAKE) -C $(DRIVERS)/libesp
	CROSS_COMPILE=$(CROSS_COMPILE) BUILD_PATH=$(BUILD_PATH)/../../../utils/linux $(MAKE) -C $(DRIVERS)/utils
	$(CC) $(CFLAGS) -o $@ $< $(OBJS) $(LDFLAGS)

clean:
	rm -rf $(BUILD_PATH)

.PHONY: all clean