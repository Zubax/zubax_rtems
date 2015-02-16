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

The Eclipse plugin can be installed as described here: <https://devel.rtems.org/wiki/Developer/Eclipse/Plugin>.

When the plugin is installed, create a new project with RTEMS toolchain, then configure the RTEMS installation path in
the project properties window on the page **Properties** → **C/C++ Build** → **RTEMS**. For example, RTEMS installation
path for ARM architecture should be configured as follows:

- Base path: `zubax_rtems/rtems-build`
- BSP path: `zubax_rtems/bsps/arm-rtems4.11`

Note that these directories will be created when RTEMS is built.

If a `make` wrapper script is used, the default build command needs to be overriden. Go to **Properties** → **C/C++ Build**,
untick **Use default build command**, and set the field **Build command** to `bash make.sh` (assuming that the wrapper script
is named `make.sh`).
