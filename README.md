Need the Linux and embedded development with C++ workload
Only works with J-link debuggers

Create a new CMake C++ IoT project for all platforms in visual studio
project name and project root directory must match

In MCU expresso, enable verbose output for both the C and C++ compilers and enable build logging.
build a release or debug version of the project
If there is no debug launch file, then export one to the MCUXpresso project root directory

In Visual Studio, copy the .vs files to the .vs folder.
Remove any automatically added source files and output folders.
Replace CMakeSettings.json and CMakeLists.txt with the one from this Repository.
Open a developer PowerShell and enter the command bash
Go into the .vs directory and enter ./convertMcuXToVisualStudio with all the required arguments. Enter with no arguments to get help.

Troubleshooting

- If an inlcude file can't be found, add additional target_include_directories commands to the CMakeLists.txt file for those source files.

- You might have to re-order the add_subdirectory commands in order to define macros in the correct order.

- If you have linker errors, you might need to add a -specs options to the C and C++ compiler options in CMakeSettings.json

- Linker errors can also be fixed by re-arranging the order of the library link in CMakeSettings.json, target_link_libraries() command.
