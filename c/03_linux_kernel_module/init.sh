#!/bin/bash
# Copyright (C) 2025 Raven Computing
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
# *         ***   Init Script for C Linux Kernel Module Projects   ***        *
# *                               INIT LEVEL 2                                *
# *                                                                           *
# #***************************************************************************#
#
# This init script sets the following substitution variables:
#
# VAR_KERNEL_MODULE_NAME: The name of the Linux kernel module when installed.

function process_files_lvl_2() {
  replace_var "KERNEL_MODULE_NAME" "$var_kernel_module_name";
  # Rename source file
  if [ -n "$var_kernel_module_name" ]; then
    if file_exists "src/module.c"; then
      move_file "src/module.c" "src/${var_kernel_module_name}.c";
    fi
  fi
}

# Validation function for the kernel module name form question.
function _validate_kernel_module_name() {
  local input="$1";
  if [ -z "$input" ]; then
    return 0;
  fi
  if [[ "$input" == "module" ]]; then
    logI "Disallowed kernel module name: '${input}'";
    return 1;
  fi
  input=$(echo "$input" |tr '[:upper:]' '[:lower:]');
  input=$(echo "$input" |tr '-' '_');
  # Validate name
  local re="^[0-9a-z_]+$";
  if ! [[ "$input" =~ $re ]]; then
    logI "Invalid kernel module name";
    logI "Only lowercase a-z, digits and '_' characters are allowed";
    return 1;
  fi
  return 0;
}

# Prompts the user to enter the name of the kernel module.
#
# Globals:
# var_kernel_module_name - The name of the Linux kernel module.
#                          Is set by this function.
#
function form_c_kernel_module_name() {
  FORM_QUESTION_ID="c.kernel.module.name";
  local default_name="";
  # shellcheck disable=SC2154
  default_name=$(echo "$var_project_name_lower" |tr '-' '_');
  logI "";
  logI "Enter the name of the Linux kernel module that this project produces:";
  logI "(Defaults to '${default_name}')";
  USER_INPUT_DEFAULT_TEXT="$default_name";
  read_user_input_text _validate_kernel_module_name;
  local entered_module_name="$USER_INPUT_ENTERED_TEXT";
  # Make sure name is lowercase
  entered_module_name=$(echo "$entered_module_name" |tr '[:upper:]' '[:lower:]');
  entered_module_name=$(echo "$entered_module_name" |tr '-' '_');
  var_kernel_module_name="$entered_module_name";
}

# Form questions

form_c_kernel_module_name;

# Project setup

project_init_copy;

project_init_license "h" "c";

project_init_process;

