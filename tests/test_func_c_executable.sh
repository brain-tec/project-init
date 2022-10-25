#!/bin/bash
# Copyright (C) 2022 Raven Computing
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# #***************************************************************************#
# *                                                                           *
# *         ***   Functionality Test for C Executables Projects   ***         *
# *                                                                           *
# #***************************************************************************#


function test_functionality() {
  test_functionality_with "test_run_c_executable.properties";
  return $?;
}

function test_functionality_result() {
  local check_files=();
  check_files+=("c/01_executable/README.md");
  check_files+=("c/01_executable/LICENSE");
  check_files+=("c/01_executable/cmake/DependencyUtil.cmake");
  check_files+=("c/01_executable/src/main/CMakeLists.txt");
  check_files+=("c/01_executable/src/main/c/main.c");
  check_files+=("c/01_executable/src/main/tests/CMakeLists.txt");
  check_files+=("c/01_executable/src/main/tests/c/test_application.c");

  assert_files_exist "${check_files[@]}";
  return $?;
}
