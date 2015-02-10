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
