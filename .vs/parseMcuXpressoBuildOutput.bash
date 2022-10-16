#! /bin/bash
###############################################################################
# Author: Ben Haubrich                                                        #
# File: parseMcuXpressoBuildOutput.bash                                       #
# Date: February 3rd, 2021                                                    #
# Synopsis: Find the paths to libraries and get compiler options              #
###############################################################################

source common.bash

#parseBuildOutput.bash [!]<-PREFIX ...> <FILE>"
#
#This function parses the build log of any compilation and prints out the"
#filtered information specified by PREFIX.
#
#Example: ./parseBuildOutput.bash -std arm-none-eabi-gcc build.log"
#This will print out all options that begin with -std"
#Example: ./parseBuildOutput.bash -std -m -l arm-none-eabi-gcc build.log"
#This will print out all options that begin with -std, -m and -l"
#Example: ./parseBuildOutput.bash -std -m -l arm-none-eabi-gcc build.log 
#This will print out all options that begin with -std, -m and -l that were"
#inlcude in all invocations of the arm-none-eabi-gcc compiler only.
parseBuildOutput() {

  if [ $# -lt 3 ]; then
    echo "Provide at least 3 arguments for parseBuildOutput"
    exit 1
  fi

  local INPUT_FILE=${@: -1}
  local COMPILER=${@: -2}
  COMPILER=`cut -d" " -f1 <<< $COMPILER`

  while [ "$1" != "$COMPILER" ]; do
    #See backslash characters, special expressions, and character classes.
    #It says find the option that is preceded by 1 or more spaces and is followed
    #by any non-whitespace character and and one or more spaces.
    #We need to special case -Xlinker because it takes an option as an argument,
    #so the entire option consists of two options.
    if [ "$1" = "-Xlinker" ]; then
      egrep -w ^$COMPILER $INPUT_FILE | egrep -o "\\$1\s+\-*\s?\S*" | sort -u
    else
      egrep -w ^$COMPILER $INPUT_FILE | egrep -o "\s+\\$1\s?\S*" | sort -u
    fi
    shift
  done
}

help() {
  echo "parseMcuXpressoBuildOutput <buildLog> <buildType>"
  echo "e.g. parseMcuXpressoBuildOutput build.txt Release"
}

parseMcuXpressoBuildOutput() {
  if [ $# -lt 2 ]; then
    help
    exit 1
  fi

  local GCC_=".*cc1\.exe"
  local GXX_=".*cc1plus\.exe"
  TEMPORARY_FILE_NAME=`createTemporaryFilename`

  ####Grab options for the C compiler
  for OPTIONS in `parseBuildOutput "-m" "-W" "-f" "-specs" "-isysroot" "-iprefix" "-imultilib" ${GCC_} $1`; do
    #Do not include macro-prefix options
    egrep --silent "(.*macro-prefix.*|.*GNU.*)" <<< ${OPTIONS}
    if [ $? -ne 0 ]; then
      CFLAGS="${CFLAGS} ${OPTIONS}"
    fi
  done
  CFLAGS=`tr -d "\"" <<< "$CFLAGS"`
  #Convert to windows path separators and escape them so we don't mess with seds own /
  CFLAGS=`convertToWindowsPathSeparator "$CFLAGS"`
  echo "      \"cCompilerFlags\": \"$CFLAGS\"," > $TEMPORARY_FILE_NAME
  LINE_NUMBER=`egrep -n -m1 \"cCompilerFlags\" ../CMakeSettings.json | cut -f1 -d ":"`
  doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
  #Convert all the windows path separators back to linux. GCC wants them that way.
  sed -i ${LINE_NUMBER}'s/\\/\//g' ../CMakeSettings.json
  
  ####Grab debug options for the C compiler
  CFLAGS=""
  for OPTIONS in `parseBuildOutput "-g" "-O" ${GCC_} $1`; do
    CFLAGS="${CFLAGS} ${OPTIONS}"
  done
  CFLAGS=`tr -d "\"" <<< "$CFLAGS"`
  #Convert to windows path separators and escape them so we don't mess with seds own /
  CFLAGS=`convertToWindowsPathSeparator "$CFLAGS"`
  echo "      \"cCompilerDebugFlags\": \"$CFLAGS\"," > $TEMPORARY_FILE_NAME
  LINE_NUMBER=`egrep -n -m1 \"cCompilerDebugFlags\" ../CMakeSettings.json | cut -f1 -d ":"`
  doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
  #Convert all the windows path separators back to linux. GCC wants them that way.
  sed -i ${LINE_NUMBER}'s/\\/\//g' ../CMakeSettings.json

  ####Grab the standard being used for the C compiler
  C_STANDARD=`parseBuildOutput "-std" ${GCC_} $1`
  C_STANDARD=`tr -d " " <<< $C_STANDARD`
  case $C_STANDARD in
    -std=gnu90|-std=c90)
      C_STANDARD=90
      ;;
    -std=gnu99|-std=c99)
      C_STANDARD=99
      ;;
    -std=gnu11|-std=c11)
      C_STANDARD=11
      ;;
    -std=gnu17|-std=c17)
      C_STANDARD=17
      ;;
  esac

  if [ "$C_STANDARD" == "" ]; then
    echo "Could not find dialect standard"
    return 1
  fi

  #Insert the string dialect starndard into ../CMakeSettings.json
  LINE_NUMBER=`egrep -n -m1 "CMAKE_C_STANDARD" ../CMakeSettings.json | cut -f1 -d ":"`
  let LINE_NUMBER++
  echo "          \"value\": \""${C_STANDARD}"\"," >> $TEMPORARY_FILE_NAME
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json

  ####Grab options for the C++ compiler
  for OPTIONS in `parseBuildOutput "-m" "-W" "-f" "-specs" "-isysroot" "-iprefix" "-imultilib" ${GXX_} $1`; do
    #Do not include macro-prefix options
    egrep --silent "(.*macro-prefix.*|.*GNU.*)" <<< ${OPTIONS}
    if [ $? -ne 0 ]; then
      CXXFLAGS="${CXXFLAGS} ${OPTIONS}"
    fi
  done
  CXXFLAGS=`tr -d "\"" <<< "$CXXFLAGS"`
  #Convert to windows path separators and escape them so we don't mess with seds own /
  CXXFLAGS=`convertToWindowsPathSeparator "$CXXFLAGS"`
  echo "      \"cxxCompilerFlags\": \"$CXXFLAGS\"," > $TEMPORARY_FILE_NAME
  LINE_NUMBER=`egrep -n -m1 \"cxxCompilerFlags\" ../CMakeSettings.json | cut -f1 -d ":"`
  doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
  #Convert all the windows path separators back to linux. GCC wants them that way.
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
  #Convert all the windows path separators back to linux. GCC wants them that way.
  sed -i ${LINE_NUMBER}'s/\\/\//g' ../CMakeSettings.json

  ####Grab debug options for the C++ compiler
  CXXFLAGS=""
  for OPTIONS in `parseBuildOutput "-g" "-O" ${GXX_} $1`; do
    CXXFLAGS="${CXXFLAGS} ${OPTIONS}"
  done
  CXXFLAGS=`tr -d "\"" <<< "$CXXFLAGS"`
  #Convert to windows path separators and escape them so we don't mess with seds own /
  CXXFLAGS=`convertToWindowsPathSeparator "$CXXFLAGS"`
  echo "      \"cxxCompilerDebugFlags\": \"$CXXFLAGS\"" > $TEMPORARY_FILE_NAME
  LINE_NUMBER=`egrep -n -m1 \"cxxCompilerDebugFlags\" ../CMakeSettings.json | cut -f1 -d ":"`
  doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
  #Convert all the windows path separators back to linux. GCC wants them that way.
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
  #Convert all the windows path separators back to linux. GCC wants them that way.
  sed -i ${LINE_NUMBER}'s/\\/\//g' ../CMakeSettings.json

  ####Grab the standard being used for the C++ compiler
  CXX_STANDARD=`parseBuildOutput "-std" ${GXX_} $1`
  CXX_STANDARD=`tr -d " " <<< "$CXX_STANDARD"`
  case $CXX_STANDARD in
    -std=gnu++98|-std=c++98)
      CXX_STANDARD=98
      ;;
    -std=gnu++03|-std=c++03)
      CXX_STANDARD=03
      ;;
    -std=gnu++11|-std=c++11)
      CXX_STANDARD=11
      ;;
    -std=gnu++14|-std=c++14)
      CXX_STANDARD=14
      ;;
    -std=gnu++17|-std=c++17)
      CXX_STANDARD=17
  esac

  if [ "$CXX_STANDARD" == "" ]; then
    echo "Could not find dialect standard"
    return 1
  fi

  #Insert the string dialect starndard into ../CMakeSettings.json
  LINE_NUMBER=`egrep -n -m1 "CMAKE_CXX_STANDARD" ../CMakeSettings.json | cut -f1 -d ":"`
  let LINE_NUMBER++
  echo "          \"value\": \""${CXX_STANDARD}"\"," >> $TEMPORARY_FILE_NAME
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json

  ####Grab linker options. Do not specify the C++ or C compiler. Just grab all of them.
  for OPTIONS in `parseBuildOutput "-Xlinker" "-nostdlib" ${TOOLCHAIN_PREFIX}... $1`; do
    OPTIONS=`echo $OPTIONS | tr -d "\""`
    LDFLAGS="${LDFLAGS} ${OPTIONS}"
  done

  #Insert the string of linker options into ../CMakeSettings.json
  LINE_NUMBER=`egrep -n -m1 "\"linkerFlags\":" ../CMakeSettings.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/      \"linkerFlags\": \"${LDFLAGS}\",/" ../CMakeSettings.json

  ####Grab all the C compiler defines
  #for DEFINE in `parseBuildOutput "-D" ${TOOLCHAIN_PREFIX}${GCC_} $1`; do
  for DEFINE in `parseBuildOutput "-D" ${GCC_} $1`; do
    CCOMPILER_DEFINES="${CCOMPILER_DEFINES} $DEFINE"
  done
  CCOMPILER_DEFINES="      \"cCompilerDefines\": \"$CCOMPILER_DEFINES\","

  #Insert the string of defines into ../CMakeSettings.json
  LINE_NUMBER=`egrep -n -m1 "cCompilerDefines" ../CMakeSettings.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/${CCOMPILER_DEFINES}/" ../CMakeSettings.json

  ####Grab all the C++ compiler defines
  for DEFINE in `parseBuildOutput "-D" ${GXX_} $1`; do
    CXXCOMPILER_DEFINES="${CXXCOMPILER_DEFINES} $DEFINE"
  done
  CXXCOMPILER_DEFINES="      \"cxxCompilerDefines\": \"$CXXCOMPILER_DEFINES\","

  #Insert the string of defines into ../CMakeSettings.json
  LINE_NUMBER=`egrep -n -m1 "cxxCompilerDefines" ../CMakeSettings.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/${CXXCOMPILER_DEFINES}/" ../CMakeSettings.json

  ####Find the linker script that sets up the memory
  for LINKER_SCRIPT_MEMORY in `ls ../$2/*.ld`; do
    egrep --silent MEMORY $LINKER_SCRIPT_MEMORY
    if [ $? -eq 0 ]; then
      break;
    fi
  done
  if [ $? -ne 0 ]; then
    echo "Could not find memory linker script"
    exit 1
  fi

  ####Find the linker script that loads libraries
  for LINKER_SCRIPT_LIBRARY in `ls ../$2/*.ld`; do
    egrep --silent GROUP $LINKER_SCRIPT_LIBRARY 1>/dev/null
    if [ $? -eq 0 ]; then
      break;
    fi
  done
  if [ $? -ne 0 ]; then
    echo "Could not find library linker script"
    exit 1
  fi

  ####Find linker main linker script that includes the rest
  for LINKER_SCRIPT_MAIN in `ls ../$2/*.ld`; do
    egrep --silent INCLUDE $LINKER_SCRIPT_MAIN
    if [ $? -eq 0 ]; then
      break;
    fi
  done
  if [ $? -ne 0 ]; then
    echo "Could not find main linker script"
    exit 1
  fi

  ####Grab all the libraries.
  LIBRARIES=`parseBuildOutput "-l" ${TOOLCHAIN_PREFIX}... $1`
  #Get rid of -l
  LIBRARIES=`echo $LIBRARIES | sed s/-l//g`
  for LIBS in `egrep \"lib.*\.a\" ${LINKER_SCRIPT_LIBRARY}`; do
    LIBRARIES="${LIBRARIES} ${LIBS}"
  done
  #Remove punctuation
  LIBRARIES=`echo $LIBRARIES | tr -d "\""`
  LIBRARIES=`echo $LIBRARIES | tr -d "\n"`
  LIBRARIES=`echo $LIBRARIES | tr -d "\r"`
  LIBRARIES=`echo $LIBRARIES | sed 's/\.a//g'`
  LIBRARIES=`echo $LIBRARIES | sed 's/\blib//g'`

  ####Insert the libraries into CMakeLists.
  sed -i "s/target_link_libraries.*/target_link_libraries (${PROJECT_NAME}.elf ${LIBRARIES})/" ../CMakeLists.txt

  ####Remove all GROUP files except for those that end in .o
  egrep -v "(\.a\")" ${LINKER_SCRIPT_LIBRARY} > ${TEMPORARY_FILE_NAME}
  cat $TEMPORARY_FILE_NAME > $LINKER_SCRIPT_LIBRARY

  ####Remove the INCLUDES from the main linker script.
  LINE_NUMBER=`egrep -n -m1 "INCLUDE" $LINKER_SCRIPT_MAIN | cut -f1 -d ":"`
  _LINE_NUMBER=$LINE_NUMBER
  while [ "$LINE_NUMBER" != "" ]; do
    sed -i "${LINE_NUMBER}s/INCLUDE.*//" $LINKER_SCRIPT_MAIN 2>/dev/null
    LINE_NUMBER=`egrep -n -m1 "INCLUDE" $LINKER_SCRIPT_MAIN | cut -f1 -d ":"`
  done
  #Re-add an include for the memory and library linker script
  sed -i "${_LINE_NUMBER}s/.*/INCLUDE \"link_memory.ld\"/" $LINKER_SCRIPT_MAIN
  let _LINE_NUMBER++
  sed -i "${_LINE_NUMBER}s/.*/INCLUDE \"link_library.ld\"/" $LINKER_SCRIPT_MAIN

  ####Rename the linker scripts
  mv ${LINKER_SCRIPT_MAIN} ../$2/link.ld
  mv ${LINKER_SCRIPT_MEMORY} ../$2/link_memory.ld
  mv ${LINKER_SCRIPT_LIBRARY} ../$2/link_library.ld

  rm $TEMPORARY_FILE_NAME

  return 0
}

####Testing
#parseMcuXpressoBuildOutput /mnt/c/Users/Ben/Desktop/build.txt /mnt/c/nxp/MCUXpressoIDE_11.3.1_5262 Debug
