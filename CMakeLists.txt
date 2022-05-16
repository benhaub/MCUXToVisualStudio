# CMakeList.txt : CMake project for Rt1060Startup, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.20)

#See https://cmake.org/cmake/help/latest/variable/CMAKE_TRY_COMPILE_TARGET_TYPE.html
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

project ("Rt1060Startup")

# Add source to this project's executable.
add_executable (Rt1060Startup.elf "utilities/fsl_str.c" "utilities/fsl_str.h" "startup/startup_mimxrt1064.c" "source/Rt1060Startup.c" "source/Rt1060Startup.h" 
"xip/evkmimxrt1064_flexspi_nor_config.c" "xip/evkmimxrt1064_flexspi_nor_config.h"
"xip/fsl_flexspi_nor_boot.c" "xip/fsl_flexspi_nor_boot.h" "board.h" "drivers/fsl_common.h" "drivers/fsl_lpuart.c" "drivers/fsl_lpuart.h" "drivers/fsl_enet.c" "drivers/fsl_enet.h" "device/fsl_device_registers.h" "device/MIMXRT1062.h" "device/MIMXRT1062_features.h" "device/system_MIMXRT1062.c" "device/system_MIMXRT1062.h" "CMSIS/core_cm7.h" "CMSIS/cmsis_compiler.h" "CMSIS/cmsis_version.h" "CMSIS/mpu_armv7.h" "CMSIS/cmsis_gcc.h"   "drivers/fsl_clock.c" "drivers/fsl_clock.h" "utilities/fsl_assert.c" "utilities/fsl_debug_console.c" "utilities/fsl_debug_console.h" "utilities/fsl_debug_console_conf.h" "source/semihost_hardfault.c" "board/board.c" "board/board.h" "board/clock_config.c" "board/clock_config.h" "board/dcd.c" "board/dcd.h" "board/fsl_phy.c" "board/fsl_phy.h" "board/pin_mux.c" "board/pin_mux.h" "component/lists/fsl_component_generic_list.c" "component/lists/fsl_component_generic_list.h" "component/serial_manager/fsl_component_serial_manager.c" "component/serial_manager/fsl_component_serial_manager.h" "component/serial_manager/fsl_component_serial_port_internal.h" "component/serial_manager/fsl_component_serial_port_uart.c" "component/serial_manager/fsl_component_serial_port_uart.h" "component/uart/fsl_adapter_lpuart.c" "component/uart/fsl_adapter_uart.h")

target_link_libraries (Rt1060Startup.elf gcc c m cr_newlib_nohost)

target_include_directories (Rt1060Startup.elf PUBLIC "board" "CMSIS" "component/serial_manager" "component/uart" "component/lists" "CMSIS" "device" "drivers" "source" "startup" "utilities" "xip")

set_property (DIRECTORY PROPERTY ADDITIONAL_CLEAN_FILES "${CMAKE_CURRENT_SOURCE_DIR}\\Debug\\${PROJECT_NAME}.bin")

# TODO: Add tests and install targets if needed.
