#
# Copyright (C) 2015 Pavel Kirienko <pavel.kirienko@zubax.com>
# Distributed under the terms of the MIT license.
#

LOCAL_DIR := $(abspath $(realpath $(dir $(lastword $(MAKEFILE_LIST)))))

flash_via_blackmagic:
	$(LOCAL_DIR)/flash_via_blackmagic.sh $(PGM)

flash_via_stlink:
	$(LOCAL_DIR)/flash_via_stlink.sh $(PGM)
