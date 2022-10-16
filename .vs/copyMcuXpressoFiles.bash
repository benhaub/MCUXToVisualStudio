#! /bin/bash
###############################################################################
# Author: Ben Haubrich                                                        #
# File: copyMcuXpressoFiles.bash                                              #
# Date: May 17th, 2022                                                        #
# Synopsis: Copy the necessary files from the MCUXpresso project to the Visual#
# Studio project and add them to CMakeLists                                   #
###############################################################################

source common.bash

help() {
  echo "Usage copyMcuXpressoFiles.bash <pathToMcuXpressoProject>"
  echo "e.g. ./copyMcuXpressoFiles.bash /mnt/d/Repos/BIC/BicEcu"
}

#Creates a CMakeLists.txt for every sub-directory provided
#and inserts a target_sources command into each CMakeLists with a PUBLIC
#declaration of each source file contained in the directory. It also places a
#target_include_directories command with CMAKE_CURRENT_LIST_DIR.
createCmakeListsForSubdir() {
  if [ $# -lt 1 ]; then
    echo "Need at least one argument for createCmakeListsForSubdir()"
    exit 1
  fi

  local SUBDIR="$1"
  mkdir -p $SUBDIR

  ####Start building the contents of CMakeLists for this sub-directory
  ls $SUBDIR | egrep '(*.\.c$|*.\.cpp$|*.\.s$|*.\.S$|*.\.h$|*.\.hpp$)'
  #If there are source files, add the target_sources command.
  if [ $? -eq 0 ]; then
    echo "target_sources(${PROJECT_NAME}.elf" > $SUBDIR/CMakeLists.txt
    echo "PRIVATE" >> $SUBDIR/CMakeLists.txt
    for SOURCES in `ls $SUBDIR | egrep '(*.\.c$|*.\.cpp$|*.\.s$|*.\.S$|*.\.h$|*.\.hpp$)'`; do
      printf "    %s\n" $SOURCES >> $SUBDIR/CMakeLists.txt
    done
    echo ")" >> $SUBDIR/CMakeLists.txt
  fi
  #If there are any library files, add the target_link_directories command
  ls $SUBDIR | egrep *.a$
  if [ $? -eq 0 ]; then
    echo "target_link_directories(${PROJECT_NAME}.elf PUBLIC \${CMAKE_CURRENT_LIST_DIR})" >> $SUBDIR/CMakeLists.txt
  fi

  echo "target_include_directories(${PROJECT_NAME}.elf PUBLIC \${CMAKE_CURRENT_LIST_DIR})" >> $SUBDIR/CMakeLists.txt
}

copyMcuXpressoFiles() {

  if [ $# -lt 1 ]; then
    help
    exit 1
  fi

  #IFS is the Input Field Separator for the for loop. This is a built-in bash
  #variable and so needs to be declared local so it does not effect all
  #subsequent for loops.
  local IFS=$'\n'
  CWD=$(pwd)
  #Grab a list of all excludes
  for ENTRY in `egrep "<entry excluding.*>" /mnt/d/Repos/BIC/BicEcu/.cproject`; do
    #Grab the root directory containing the excluded items
    ROOT_EXCLUDE_DIR=`egrep -o 'name="[^"]*"' <<< "$ENTRY" | cut -d"=" -f2 | tr -d "\""`
    EXCLUDED_ITEMS=`egrep -o 'excluding="[^"]*"' <<< "$ENTRY" | cut -d"=" -f2 | tr -d "\""`
    local IFS='|'
    for ITEM in $EXCLUDED_ITEMS; do
      EXCLUDE_PATH="${EXCLUDE_PATH} ${ROOT_EXCLUDE_DIR}/${ITEM}"
    done
  done

  ####Copy all dirs and sub-dirs that contain source files
  cp -r $1/*.jlink ../$DIRS
  local IFS=$'\n'
  for DIRS in `ls -1 $1`; do
    #Find any linker scripts and jlink scripts and copy those
    ls -1R $1/$DIRS | egrep --silent '(*.\.ld$)'
    if [ $? -eq 0 ]; then
       cp -r $1/$DIRS/*.ld ../$DIRS
   fi
   ls -1R $1/$DIRS | egrep --silent '(*.\.c$|*.\.cpp$|*.\.s$|*.\.S$|*.\.h$|*.\.hpp$)'
   if [ $? -ne 0 ]; then
     continue
   else
     cp -r $1/$DIRS ..
     pushd . > /dev/null
     cd $1
     local IFS=$'\n'
     ####Place a CMakeLists.txt in every directory.
     for SUBDIRS in `ls -1R $DIRS | egrep .*:$ | tr -d ":"`; do
       popd > /dev/null
       local IFS=' '
       #Build a list of all directories and sub-directories, but do not include
       #excluded directories in this list.
       for EXCLUDE in $EXCLUDE_PATH; do
         #All directoires were copied before, now remove the excluded ones.
         #rm -rf ../$EXCLUDE
         #Populate the ALL_DIRS variable with all directories execept for
         #excluded ones. That way when add_subdirectory commands are added,
         #we won't add subdirectories for excluded items.
         egrep $EXCLUDE <<< $SUBDIRS
         if [ $? -eq 0 ]; then
           IS_EXCLUDED=0
           break
         else
           IS_EXCLUDED=1
         fi
       done
       if [ $IS_EXCLUDED -ne 0 ]; then
         ALL_DIRS="$ALL_DIRS $SUBDIRS"
       fi
       createCmakeListsForSubdir "../$SUBDIRS"
       pushd . > /dev/null
       cd $1
     done
     popd > /dev/null
   fi
  done
  
  ####add_executable needs at least one source file. Try to find a a c or cpp
  #### file named main and add it.
  pushd . > /dev/null
  cd ..
  MAIN=`find . -type f -iname main\.`
  TEMPORARY_FILENAME=`createTemporaryFilename`
  echo $MAIN > $TEMPORARY_FILENAME
  sed -i 's/\//\\\//g' $TEMPORARY_FILENAME
  LINE_NUMBER=`egrep -n -m1 "add_executable" CMakeLists.txt | cut -f1 -d ":"`
  sed -i "${LINE_NUMBER}s/add_executable.*/add_executable \(\${PROJECT_NAME}.elf \"\")/" CMakeLists.txt
  popd 2>/dev/null
  
  ####Add each subdirectory to the top level CMakeLists add_subdirectory command
  local IFS=' '
  TEMPORARY_FILENAME=`createTemporaryFilename`
  #Remove all old add_subdirectory at each line below..
  sed -i "/add_subdirectory\s*\(.*\)/d" ../CMakeLists.txt
  #We want to put all the add_subdirectory command below the target_link_library command
  LINE_NUMBER=`egrep -n -m1 "target_link_libraries\s*\(.*\)" ../CMakeLists.txt | cut -f1 -d ":"`
  let LINE_NUMBER++
  for DIRS in $ALL_DIRS; do
    echo $DIRS > ../$TEMPORARY_FILENAME
    sed -i 's/\//\\\//g' ../$TEMPORARY_FILENAME
    sed -i "${LINE_NUMBER}s/.*/add_subdirectory \(`tail -1 ../${TEMPORARY_FILENAME}`\)/" ../CMakeLists.txt
    #Append a new line below line number to prep for the next insertion
    sed -i ${LINE_NUMBER}G ../CMakeLists.txt
    let LINE_NUMBER++
  done
  
  rm -f ../$TEMPORARY_FILENAME
}
