# CMakeList.txt : CMake project for Rt1060Startup, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.20)

project ("Rt1060Startup")

#Set the working directory when debugging. Requires >=3.8
#set_target_properties(
	#Rt1060Startup PROPERTIES
	#VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}\\out\\build"
#)

# Add source to this project's executable.
add_executable (Rt1060Startup.elf "startup_mimxrt1064.c" "Rt1060Startup.c" "Rt1060Startup.h" 
"evkmimxrt1064_flexspi_nor_config.c" "evkmimxrt1064_flexspi_nor_config.h"
"fsl_flexspi_nor_boot.c" "fsl_flexspi_nor_boot.h" "board.h"   "drivers/fsl_common.h" "device/fsl_device_registers.h" "device/MIMXRT1062.h" "device/MIMXRT1062_features.h" "device/system_MIMXRT1062.c" "device/system_MIMXRT1062.h" "CMSIS/core_cm7.h" "CMSIS/cmsis_compiler.h" "CMSIS/cmsis_version.h" "CMSIS/mpu_armv7.h" "CMSIS/cmsis_gcc.h"   "drivers/fsl_clock.c" "drivers/fsl_clock.h")

target_include_directories(Rt1060Startup.elf PUBLIC "device" "drivers" "CMSIS")

set_property(DIRECTORY PROPERTY ADDITIONAL_CLEAN_FILES "${CMAKE_CURRENT_SOURCE_DIR}\\Debug\\${PROJECT_NAME}.bin")

# TODO: Add tests and install targets if needed.
