#! /bin/bash
###############################################################################
# Author: Ben Haubrich                                                        #
# File: setupVsFiles.bash                                                     #
# Date: May 18th, 2022                                                        #
# Synopsis: Fill in variable names specific to the visual studio project for  #
# conversion template files.
###############################################################################

source common.bash

help() {
  echo "Usage setupVsFiles.bash"
  echo "e.g. ./copyMcuXpressoFiles.bash"
}

setupVsFiles() {
  ####Place the project name in all the places it needs to go
  LINE_NUMBER=`egrep -n -m1 \"projectName\" tasks.vs.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/  \"projectName\": \"${PROJECT_NAME}\",/" tasks.vs.json
  LINE_NUMBER=`egrep -n -m1 \"projectName\" launch.vs.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/  \"projectName\": \"${PROJECT_NAME}\",/" launch.vs.json
  LINE_NUMBER=`egrep -n -m1 \"name\" launch.vs.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/      \"name\": \"${PROJECT_NAME}\",/" launch.vs.json
  LINE_NUMBER=`egrep -n -m1 "project\s?\(\".*\".*\)" ../CMakeLists.txt | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/project (\"${PROJECT_NAME}\" C CXX ASM)/" ../CMakeLists.txt
  #Replace all occurances of projectName with the project name
  sed -i "s/\${projectName}/${PROJECT_NAME}/g" tasks.vs.json
  sed -i "s/\${projectName}/${PROJECT_NAME}/g" launch.vs.json
}
