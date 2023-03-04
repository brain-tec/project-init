#!/bin/bash
# Copyright (C) 2023 Raven Computing
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
# *               ***   Init Script for JavaScript Projects   ***             *
# *                                 INIT LEVEL 1                              *
# *                                                                           *
# #***************************************************************************#
#
# This init script sets the following substitution variables:
#
# VAR_NODEJS_VERSION: The version number of Node.js to be used,
#                     e.g. '16'
# VAR_NODEJS_VERSION_LABEL: The version label of Node.js to be used,
#                           e.g. 'Node.js 16'


function process_files_lvl_1() {
  if [ -n "$var_integration_docker_enabled" ]; then
    replace_var "SCRIPT_RUN_ISOLATED_OPT"            "$var_script_run_isolated_opt";
    replace_var "SCRIPT_BUILD_ISOLATED_ARGFLAG"      "$var_script_build_isolated_argflag";
    replace_var "SCRIPT_BUILD_ISOLATED_ARGARRAY"     "$var_script_build_isolated_argarray";
    replace_var "SCRIPT_BUILD_ISOLATED_ARGARRAY_ADD" "$var_script_build_isolated_argarray_add";
    replace_var "SCRIPT_BUILD_ISOLATED_ARGPARSE"     "$var_script_build_isolated_argparse";
    replace_var "SCRIPT_RUN_ISOLATED_MAIN"           "$var_script_run_isolated_main";
    replace_var "SCRIPT_RUN_ISOLATED_HINT1"          "$var_script_run_isolated_hint1";
    if [[ "$var_integration_docker_enabled" == "0" ]]; then
      # Remove entire .docker dir in source root
      rm -r "$var_project_dir/.docker";
      if (( $? != 0 )); then
          failure "Failed to remove template source docker integration directory";
      fi
      find_all_files;
    fi
  fi

  replace_var "NODEJS_VERSION"       "$var_nodejs_version";
  replace_var "NODEJS_VERSION_LABEL" "$var_nodejs_version_label";
}

# [API function]
# Prompts the user to enter the Node.js version to use for the project.
#
# The provided answer can be queried in source template files via the
# VAR_NODEJS_VERSION and VAR_NODEJS_VERSION_LABEL substitution variables.
# The associated shell global variables are set by this function.
#
# Globals:
# var_nodejs_version       - The Node.js version string.
#                            Is set by this function.
# var_nodejs_version_label - The Node.js version label string.
#                            Is set by this function.
#
function form_nodejs_version() {
  FORM_QUESTION_ID="js.nodejs.version";
  logI "";
  logI "Specify the Node.js version to be used by the project:";
  # We alienate the SUPPORTED_LANG_VERSIONS_* global vars here
  read_user_input_selection "${SUPPORTED_LANG_VERSIONS_LABELS[@]}";
  var_nodejs_version=${SUPPORTED_LANG_VERSIONS_IDS[USER_INPUT_ENTERED_INDEX]};
  var_nodejs_version_label=${SUPPORTED_LANG_VERSIONS_LABELS[USER_INPUT_ENTERED_INDEX]};
}

# Prompts the user to enter whether he wants Docker integration.
#
function form_js_add_docker_integration() {
  FORM_QUESTION_ID="js.integration.docker";
  logI "";
  logI "Would you like to enable Docker integration? (Y/n)";
  read_user_input_yes_no true;
  if [[ "$USER_INPUT_ENTERED_BOOL" == "true" ]]; then
    var_integration_docker_enabled="1";
    var_script_run_isolated_opt="$(load_var SCRIPT_RUN_ISOLATED_OPT)";
    var_script_build_isolated_argflag="$(load_var SCRIPT_BUILD_ISOLATED_ARGFLAG)";
    var_script_build_isolated_argarray="$(load_var SCRIPT_BUILD_ISOLATED_ARGARRAY)";
    var_script_build_isolated_argarray_add="$(load_var SCRIPT_BUILD_ISOLATED_ARGARRAY_ADD)";
    var_script_build_isolated_argparse="$(load_var SCRIPT_BUILD_ISOLATED_ARGPARSE)";
    var_script_run_isolated_main="$(load_var SCRIPT_RUN_ISOLATED_MAIN)";
    var_script_run_isolated_hint1="$(load_var SCRIPT_RUN_ISOLATED_HINT1)";
  else
    var_integration_docker_enabled="0";
    var_script_build_isolated_opt="";
    var_script_build_isolated_argflag="";
    var_script_build_isolated_argarray="";
    var_script_build_isolated_argarray_add="";
    var_script_build_isolated_argparse="";
    var_script_build_isolated_main="";
    var_script_run_isolated_hint1="";
  fi
}

# Specify supported versions for Node.js
# We use the standard API for language version specification for now
add_lang_version "14" "Node.js 14";
add_lang_version "16" "Node.js 16";
add_lang_version "18" "Node.js 18";

# Let the user choose a JavaScript project type
select_project_type "js" "JavaScript";
selected_name="$FORM_PROJECT_TYPE_NAME";
selected_dir="$FORM_PROJECT_TYPE_DIR";

proceed_next_level "$selected_dir";
