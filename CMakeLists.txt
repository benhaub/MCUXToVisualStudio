# CMakeList.txt : CMake project MCUX to Visual Studio converions
#
cmake_minimum_required (VERSION 3.13)

#See https://cmake.org/cmake/help/latest/variable/CMAKE_TRY_COMPILE_TARGET_TYPE.html
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

project ("")

# Add source to this project's executable.
add_executable ()

#The order of linked libraries matters!
target_link_libraries ()
add_subdirectory ("")

set_property (DIRECTORY PROPERTY ADDITIONAL_CLEAN_FILES "${CMAKE_CURRENT_SOURCE_DIR}\\Debug\\${PROJECT_NAME}.bin")

# TODO: Add tests and install targets if needed.