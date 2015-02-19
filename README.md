# Zubax RTEMS

Building scripts and tools for [RTEMS RTOS](http://rtems.org).

## Building

### General notes

Building process is completely automated with the script `build_rtems.sh`.
This chapter describes how to use this script in a custom application.

Note that first time build requires Internet connection and takes around 40 minutes to complete.

### Command line options

- `--cpu`
  - Argument: CPU family name.
  - Description: Defines RTEMS target architecture.
  - Required: Yes
  - Example: `--cpu=arm`
- `--bsp`
  - Argument: Name of the board support package (BSP).
  - Description: Defines RTEMS BSP to use with the application.
  - Required: Yes
  - Example: `--bsp=stm32f4`
- `--overwrite-bsp-dir`
  - Argument: Absolute path to an external BSP directory.
  - Description: Allows to use an external board support package (BSP) sources.
    If directory name of the custom BSP conflicts with directory name of a standard BSP, the latter will be removed.
    Use this option if your application needs custom BSP.
  - Required: No
  - Example: `--overwrite-bsp-dir=src/my-custom-bsp`
- `--amend-bsp-dir`
  - Argument: Absolute path to an external BSP directory.
  - Description: Allows to overwrite some files of an existing BSP using `cp -rf`.
    Use this option if your application only needs to make some minor changes to a standard BSP.
  - Required: No
  - Example: `--amend-bsp-dir=src/stm32f4`
- `--remove-unused-bsp`
  - Description: Instructs the builder to remove all architectures and BSP that are unused in this build.
    This can speed up the build significantly.
  - Required: No
  - Example: `--remove-unused-bsp`

### Environment variables

#### RTEMS_CONFIGURE_EXTRA_OPTIONS

This variable allows the application to pass additional options to the RTEMS `configure` script.
Please refer to the RTEMS documentation to learn more about available options, or just execute `rtems/configure --help`
to see the list.

Example:

```bash
export RTEMS_CONFIGURE_EXTRA_OPTIONS="\
--disable-itron \
--disable-networking \
--disable-multiprocessing \
USE_TICKS_FOR_STATISTICS=1 \
CXXFLAGS_FOR_TARGET=-fno-exceptions \
"
```

#### RTEMS_RSB_EXTRA_OPTIONS

This variable allows the application to pass additional options to RTEMS source builder (RSB).
Please refer to the RSB documentation to learn more about available options.

Example:

```bash
export RTEMS_RSB_EXTRA_OPTIONS="--targetcxxflags=-fno-exceptions --libstdcxxflags=-fno-exceptions"
```

### Build artifacts

When `build_rtems.sh` completes successfully, the following outputs are generated:

- RTEMS GCC toolchain under `zubax_rtems/toolchain`
- RTEMS libraries under `zubax_rtems/bsps`
- Environment configuration file `zubax_rtems/env.sh`

The file `env.sh` is the main product of the build process. The application needs to source this file before invoking
`make`. When sourced, this file alters the `PATH` variable so it contains references to the RTEMS toolchain, and also
it sets the variable `RTEMS_MAKEFILE_PATH` which is required for the RTEMS build system.

When `env.sh` is sourced, the application can use `make` as shown in the RTEMS example applications.
However, it may be beneficial to use `application.mk` instead of relying on the raw RTEMS build system, as it
provides a few convenient abstractions. Since there's no user manual available for `application.mk`, the reader is
advised to read the source to learn how to use it.

## Example 1

This example shows a possible way to build RTEMS for STM32.

```bash
# Complete list of BSP-specific options can be found in "<bsp-dir>/configure.ac".
export STM32F4_HSE_OSCILLATOR=8000000
export STM32F4_SYSCLK=8000000
export STM32F4_HCLK=$STM32F4_SYSCLK
export STM32F4_PCLK1=8000000
export STM32F4_PCLK2=$STM32F4_SYSCLK
export STM32F4_USART_BAUD=115200
export STM32F4_ENABLE_USART_1=""
export STM32F4_ENABLE_USART_2="1"
export STM32F4_ENABLE_USART_3="1"
export STM32F4_ENABLE_UART_4=""
export STM32F4_ENABLE_UART_5=""
export STM32F4_ENABLE_USART_6=""
export STM32F4_ENABLE_I2C1=""
export STM32F4_ENABLE_I2C2=""
export BSP_PRINT_EXCEPTION_CONTEXT="1"

# Optimizing for size - see https://devel.rtems.org/wiki/Projects/TinyRTEMS
export RTEMS_CONFIGURE_EXTRA_OPTIONS="\
--disable-itron \
--disable-networking \
--disable-multiprocessing \
USE_TICKS_FOR_STATISTICS=1 \
CXXFLAGS_FOR_TARGET='-fno-exceptions -fno-rtti' \
"

export RTEMS_RSB_EXTRA_OPTIONS="--targetcxxflags=-fno-exceptions --libstdcxxflags=-fno-exceptions"

zubax_rtems/build_rtems.sh --cpu=arm --bsp=stm32f105rc
```

## Eclipse configuration

### RTEMS Eclipse plugin

The Eclipse plugin can be installed as
[described on the RTEMS wiki](https://devel.rtems.org/wiki/Developer/Eclipse/Plugin). When the plugin is installed,
create a new project with RTEMS toolchain, then configure the RTEMS installation path on the RTEMS properties page at
**Project** → **Properties** → **C/C++ Build** → **RTEMS**. For example, RTEMS installation path for architecture ARM
and BSP `stm32f105rc` should be configured as follows:

- Base path: `zubax_rtems/bsps`
- BSP path: `zubax_rtems/bsps/arm-rtems4.11/stm32f105rc`

Note that these directories will be created when RTEMS is built. The example above shows relative pathes, but it is
preferred to use absolute pathes instead.

### Build settings

If a `make` wrapper script is used, the default build command needs to be overriden. Go to **Project** → **Properties**
→ **C/C++ Build**, untick **Use default build command**, and set the field **Build command** to `bash make.sh`
(assuming that the wrapper script is named `make.sh`).

### GDB debugging

#### ARM - Black Magic Probe

These instructions are valid for ARM architecture and [Black Magic Probe](http://www.blacksphere.co.nz/main/blackmagic)
as a debugger.

- Go **Window** → **Preferences** → **Run/Debug** → **Launching** → **Default Launchers**:
  - Select `GDB Hardware Debugging` → `[Debug]`, then tick *only* `Legacy GDB Hardware Debugging Launcher`, and make
  sure that the option for GDB (DSF) is disabled.
- Go **Run** → **Debug Configurations**:
  - Invoke the context menu for `GDB Hardware Debugging`, select New.
  - Tab `Debugger`:
    - Set the field `GDB Command` to the absolute path to your GDB executable `arm-rtems4.11-gdb`. To find out the
    absolute path, source the file `env.sh` and execute `which arm-rtems4.11-gdb`.
    - Untick `Use remote target`.
  - Tab `Startup`:
    - If a boot loader is used, make sure that `Image offset` is configured correctly.
    - Enter the following in the field `Initialization commands`:

```gdb
target extended /dev/ttyACM0      # Update the serial port name according to your setup

monitor swdp_scan                 # Use jtag_scan instead if necessary
attach 1
monitor vector_catch disable hard

set mem inaccessible-by-default off
monitor option erase
set print pretty
```
