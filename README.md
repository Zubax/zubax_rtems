# Zubax RTEMS

Building scripts and tools for [RTEMS RTOS](http://rtems.org).

## Building

The example below shows how to build RTEMS for STM32.

```bash
# Complete list of available options can be found in "<bsp-dir>/configure.ac".
export STM32F4_ENABLE_USART_2="1"
export STM32F4_ENABLE_USART_3=""
export STM32F4_ENABLE_I2C1=""

./build_rtems.sh --cpu=arm           \
                 --bsp=stm32f105rc   \
                 --remove-unused-bsp
```

Scratch build requires Internet connection and takes around 40 minutes to complete.

## Eclipse configuration

### RTEMS Eclipse plugin

The Eclipse plugin can be installed as
[described on the RTEMS wiki](https://devel.rtems.org/wiki/Developer/Eclipse/Plugin). When the plugin is installed,
create a new project with RTEMS toolchain, then configure the RTEMS installation path on the RTEMS properties page at
**Project** → **Properties** → **C/C++ Build** → **RTEMS**. For example, RTEMS installation path for architecture `ARM`
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
target extended <BLACK_MAGIC_SERIAL_PORT>

monitor swdp_scan   # Use jtag_scan instead if necessary
attach 1
monitor vector_catch disable hard

set mem inaccessible-by-default off
monitor option erase
set print pretty
```
