#! /bin/bash
###############################################################################
# Author: Ben Haubrich                                                        #
# File: parseMcuExpressoBuildOutput.bash                                      #
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
      egrep -w ^$COMPILER $INPUT_FILE | egrep -o "\\$1\s+\-*\S*" | sort -u
    else
      egrep -w ^$COMPILER $INPUT_FILE | egrep -o "\s+\\$1\S*" | sort -u
    fi
    shift
  done
}

help() {
  echo "parseMcuExpressoBuildOutput <buildLog> <pathToMCUXInstall>"
  echo "e.g. parseMcuExpressoBuildOutput build.txt /mnt/c/nxp/MCUXpressoIDE_11.3.1_5262"
}

parseMcuExpressoBuildOutput() {
  if [ $# -lt 2 ]; then
    help
    exit 1
  fi

  local GCC_=`sed 's/.exe//' <<< "${GCC}"`
  local GXX_=`sed 's/.exe//' <<< "${GXX}"`
  TEMPORARY_FILE_NAME=`createTemporaryFilename`

  ####Grab options for the C compiler
  for OPTIONS in `parseBuildOutput "-m" "-f" "-s" "-g" "-O" ${TOOLCHAIN_PREFIX}${GCC_} $1`; do
    CFLAGS="${CFLAGS} ${OPTIONS}"
  done
  CFLAGS=`tr -d "\"" <<< "$CFLAGS"`
  #Convert to windows path separators and escape them so we don't mess with seds own /
  CFLAGS=`convertToWindowsPathSeparator "$CFLAGS"`
  echo "      \"cCompilerFlags\": \"$CFLAGS\"," >> $TEMPORARY_FILE_NAME
  LINE_NUMBER=`egrep -n -m1 \"cCompilerFlags\" ../CMakeSettings.json | cut -f1 -d ":"`
  doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
  #Convert all the windows path separators back to linux. GCC wants them that way.
  sed -i ${LINE_NUMBER}'s/\\/\//g' ../CMakeSettings.json
  #doubleUpWindowsPathSeparators ../CMakeSettings.json $LINE_NUMBER

  ####Grab options for the C++ compiler
  for OPTIONS in `parseBuildOutput "-std" "-m" "-f" "-specs" "-g" ${TOOLCHAIN_PREFIX}${GXX_} $1`; do
    CXXFLAGS="${CXXFLAGS} ${OPTIONS}"
  done
  CXXFLAGS="      \"cxxCompilerFlags\": \"$CXXFLAGS\""
  LINE_NUMBER=`egrep -n -m1 \"cxxCompilerFlags\" ../CMakeSettings.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/${CXXFLAGS}/" ../CMakeSettings.json

 ####Grab linker options. Do not specify the C++ or C compiler. Just grab all of them.
 for OPTIONS in `parseBuildOutput "-Xlinker" "-nostdlib" ${TOOLCHAIN_PREFIX}... $1`; do
   OPTIONS=`echo $OPTIONS | tr -d "\""`
   LDFLAGS="${LDFLAGS} ${OPTIONS}"
 done
 #Escape quotes
 LDFLAGS="      \"linkerFlags\": \"${LDFLAGS}\""
 LINE_NUMBER=`egrep -n -m1 \"linkerFlags\" ../CMakeSettings.json | cut -f1 -d ":"`
 sed -i ${LINE_NUMBER}"s/.*/${LDFLAGS}/" ../CMakeSettings.json

  ####Grab all the C compiler defines
  for DEFINE in `parseBuildOutput "-D" ${TOOLCHAIN_PREFIX}${GCC_} $1`; do
    CCOMPILER_DEFINES="${CCOMPILER_DEFINES} $DEFINE"
  done
  CCOMPILER_DEFINES="      \"cCompilerDefines\": \"$CCOMPILER_DEFINES\","

  ####Insert the string of defines into ../CMakeSettings.json
  LINE_NUMBER=`egrep -n -m1 "cCompilerDefines" ../CMakeSettings.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/${CCOMPILER_DEFINES}/" ../CMakeSettings.json

  ####Grab all the C++ compiler defines
  for DEFINE in `parseBuildOutput "-D" ${TOOLCHAIN_PREFIX}${GXX_} $1`; do
    CXXCOMPILER_DEFINES="${CXXCOMPILER_DEFINES} $DEFINE"
  done
  CXXCOMPILER_DEFINES="      \"cxxCompilerDefines\": \"$CXXCOMPILER_DEFINES\","

  ####Insert the string of defines into ../CMakeSettings.json
  LINE_NUMBER=`egrep -n -m1 "cxxCompilerDefines" ../CMakeSettings.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/${CXXCOMPILER_DEFINES}/" ../CMakeSettings.json

  ####Find the linker script that sets up the memory
  for LINKER_SCRIPT_MEMORY in `ls ../*.ld`; do
    egrep MEMORY $LINKER_SCRIPT_MEMORY 1>/dev/null
    if [ $? -eq 0 ]; then
      break;
    fi
  done
  if [ $? -ne 0 ]; then
    echo "Could not find memory linker script"
    exit 1
  fi

  ####Find the linker script that loads libraries
  for LINKER_SCRIPT_LIBRARY in `ls ../*.ld`; do
    egrep GROUP $LINKER_SCRIPT_LIBRARY 1>/dev/null
    if [ $? -eq 0 ]; then
      break;
    fi
  done
  if [ $? -ne 0 ]; then
    echo "Could not find library linker script"
    exit 1
  fi

  ####Find linker main linker script that includes the rest
  for LINKER_SCRIPT_MAIN in `ls ../*.ld`; do
    egrep INCLUDE $LINKER_SCRIPT_MAIN
    if [ $? -eq 0 ]; then
      break;
    fi
  done
  if [ $? -ne 0 ]; then
    echo "Could not find main linker script"
    exit 1
  fi

  ####Grab all the libraries.
  #Since you can only load static libraries from linker scripts we can get away with searching
  #for all .a files.
  for LIBS in `egrep \"lib.*\.a\" ${LINKER_SCRIPT_LIBRARY}`; do
    LIBRARIES="${LIBRARIES} ${LIBS}"
  done
  #Remove punctuation
  LIBRARIES=`echo $LIBRARIES | tr -d "\""`
  LIBRARIES=`echo $LIBRARIES | tr -d "\n"`
  LIBRARIES=`echo $LIBRARIES | tr -d "\r"`
  LIBRARIES=`echo $LIBRARIES | sed 's/\.a//g'`
  LIBRARIES=`echo $LIBRARIES | sed 's/\blib//g'`

  ####Remove the library linker script
  rm -f ../${LINKER_SCRIPT_LIBRARY}
  #Remove the include to the library linker script
  sed -i "/INCLUDE.*\.library/d" ../$LINKER_SCRIPT_MAIN 2>/dev/null

  ####Get the CMake project name
  PROJECT_NAME=`egrep '^project+\s\(' ../CMakeLists.txt`
  #Remove punctuation. Includes both stylistic and syntax related removals
  PROJECT_NAME=`echo ${PROJECT_NAME} | tr -d "\""`
  PROJECT_NAME=`echo $PROJECT_NAME | tr -d "\n"`
  PROJECT_NAME=`echo $PROJECT_NAME | tr -d "\r"`
  PROJECT_NAME=`echo ${PROJECT_NAME} | tr -d "\("`
  PROJECT_NAME=`echo ${PROJECT_NAME} | tr -d "\)"`
  PROJECT_NAME=`echo ${PROJECT_NAME} | sed s/project//`
  PROJECT_NAME=`echo ${PROJECT_NAME} | sed s/" "//`

  ####Insert the libraries into CMakeLists.
  sed -i "s/target_link_libraries.*/target_link_libraries (${PROJECT_NAME}.elf ${LIBRARIES})/" ../CMakeLists.txt

  ####Update the path to the memory linker script.
  cd ..
  PATH_TO_LINKER_SCRIPTS=`pwd`
  cd .vs
  PATH_TO_LINKER_SCRIPTS=`convertToWindowsDriveLetter $PATH_TO_LINKER_SCRIPTS`
  PATH_TO_LINKER_SCRIPTS=`convertToWindowsPathSeparator $PATH_TO_LINKER_SCRIPTS`
  LINE_NUMBER=`egrep -n -m1 "INCLUDE" $LINKER_SCRIPT_MAIN | cut -f1 -d ":"`
  sed -i "$LINE_NUMBER/INCLUDE.*/INCLUDE \"${PATH_TO_LINKER_SCRIPTS}\\${LINKER_SCRIPT_MEMORY}\"/" ../$LINKER_SCRIPT_MAIN 2>/dev/null

  rm $TEMPORARY_FILE_NAME

  return 0
}

####Testing
parseMcuExpressoBuildOutput /mnt/c/Users/Ben/Desktop/build.txt /mnt/c/nxp/MCUXpressoIDE_11.3.1_5262
