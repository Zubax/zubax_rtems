#
# Copyright (C) 2015 Pavel Kirienko <pavel.kirienko@zubax.com>
# Distributed under the terms of the MIT license.
#

LOCAL_DIR := $(abspath $(realpath $(dir $(lastword $(MAKEFILE_LIST)))))

EXEC ?= firmware.exe
PGM ?= ${ARCH}/$(EXEC)

MANAGERS ?= all

#
# RTEMS makefiles
#
ifndef RTEMS_MAKEFILE_PATH
  $(error RTEMS environment is not configured. Have you sourced env.sh?)
endif

VARIANT ?= OPTIMIZE
ifeq ($(VARIANT),DEBUG)
else ifeq ($(VARIANT),OPTIMIZE)
else
  $(error Unrecognized build variant: $(VARIANT))
endif

include $(RTEMS_MAKEFILE_PATH)/Makefile.inc
include $(RTEMS_CUSTOM)
include $(PROJECT_ROOT)/make/leaf.cfg

#
# Rules
#
COBJS_ = $(CSRCS:.c=.o)
COBJS = $(COBJS_:%=${ARCH}/%)

CXXOBJS_ = $(CXXSRCS:.cpp=.o)
CXXOBJS = $(CXXOBJS_:%=${ARCH}/%)

OBJS = $(COBJS) $(CXXOBJS)

# Copying directory structure to the output directory
$(info $(foreach var,$(dir $(CSRCS) $(CXXSRCS)),$(shell mkdir -vp "${ARCH}/$(var)")))

include $(LOCAL_DIR)/flashers/rules.mk

all:    ${ARCH} $(PGM)

$(PGM): $(OBJS)
	$(make-cxx-exe)
