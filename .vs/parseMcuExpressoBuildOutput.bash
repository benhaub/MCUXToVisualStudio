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
#This script parses the build log of any compilation and prints out the"
#filtered information specified by PREFIX. The opposite can be done by"
#placing a \`!' in front of Type to remove that information from the output"
#instead of isolating it."
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
    egrep -w ^$COMPILER $INPUT_FILE | egrep -o "\s+\\$1\S*" | sort -u
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
  for OPTIONS in `parseBuildOutput "-m" "-f" "-s" "-n" "-O" ${TOOLCHAIN_PREFIX}${GCC_} $1`; do
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
  for OPTIONS in `parseBuildOutput "-std" "-m" "-f" "-specs" ${TOOLCHAIN_PREFIX}${GXX_} $1`; do
    CXXFLAGS="${CXXFLAGS} ${OPTIONS}"
  done
  CXXFLAGS="      \"cxxCompilerFlags\": \"$CXXFLAGS\""
  LINE_NUMBER=`egrep -n -m1 \"cxxCompilerFlags\" ../CMakeSettings.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/${CXXFLAGS}/" ../CMakeSettings.json

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

  ####Find the linker script which references the libraries to link and get
  ####the paths
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
  #Clear up the old paths in the linker script to replace with the new ones
  sed -i '/SEARCH_DIR.*/d' $LINKER_SCRIPT_LIBRARY 2>/dev/null

  #Grab all the paths to search for libraries and insert them into the linker script
  for PATHS in `parseBuildOutput "-L" ${TOOLCHAIN_PREFIX} $1 | tr -d "\"" | tr -d "'" | sed 's/-L//'`; do
    echo "SEARCH_DIR (\"$PATHS\")" >> $LINKER_SCRIPT_LIBRARY
  done

  #The rest of the libraries are in the LIBRARY_PATH variable
  FIELD=1
  PATHS=`egrep LIBRARY_PATH $1 | sort -u | cut -d";" -f$FIELD`
  while [ "" != "$PATHS" ]; do
    PATHS=`sed "s/LIBRARY_PATH\=//" <<< $PATHS`
    echo "SEARCH_DIR (\"$PATHS\")" >> $LINKER_SCRIPT_LIBRARY
    let FIELD++
    PATHS=`egrep LIBRARY_PATH $1 | sort -u | cut -d";" -f$FIELD`
  done

  ####Find linker main linker script that includes the rest and update the paths
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
  #Update the path
  cd ..
  PATH_TO_LINKER_SCRIPTS=`pwd`
  cd .vs
  PATH_TO_LINKER_SCRIPTS=`convertToWindowsDriveLetter $PATH_TO_LINKER_SCRIPTS`
  PATH_TO_LINKER_SCRIPTS=`convertToWindowsPathSeparator $PATH_TO_LINKER_SCRIPTS`
  LINE_NUMBER=`egrep -n -m1 "INCLUDE" $LINKER_SCRIPT_MAIN | cut -f1 -d ":"`
  sed -i "$LINE_NUMBER/INCLUDE.*/INCLUDE \"${PATH_TO_LINKER_SCRIPTS}\\${LINKER_SCRIPT_LIBRARY}\"/" ../$LINKER_SCRIPT_MAIN 2>/dev/null
  let LINE_NUMBER++
  sed -i "$LINE_NUMBER/INCLUDE.*/INCLUDE \"${PATH_TO_LINKER_SCRIPTS}\\${LINKER_SCRIPT_MEMORY}\"/" ../$LINKER_SCRIPT_MAIN 2>/dev/null

  rm $TEMPORARY_FILE_NAME

  return 0
}

####Testing
#parseMcuExpressoBuildOutput build.txt /mnt/c/nxp/MCUXpressoIDE_11.3.1_5262
