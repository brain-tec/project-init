#!/bin/bash
# Copyright (C) 2024 Raven Computing
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
# *               ***   Functionality Test Driver Script   ***                *
# *                                                                           *
# #***************************************************************************#
#
# This is the entry point for a functionality test.
#


# The properties config file to be loaded for the test runs,
# relative to the test path.
readonly _TESTS_PROPERTIES="resources/project.properties";

# The associative array for the form answer data.
declare -A _FORM_ANSWERS;


# Loads the configuration files used in test mode and stores the
# data in the corresponding global variables.
#
# The caller should check the relevant PROJECT_INIT_TESTS_ACTIVE
# and PROJECT_INIT_TESTS_RUN_CONFIG environment variables before
# calling this function.
#
# Globals:
# _FORM_ANSWERS - The configured form answers from the test run file.
#                 Is declared and initialized by this function.
#
function _load_test_configuration() {
  if [ -n "$PROJECT_INIT_TESTS_RUN_CONFIG" ]; then
    if ! _read_properties "$PROJECT_INIT_TESTS_RUN_CONFIG" _FORM_ANSWERS; then
      logE "The configuration file for the test run has errors:";
      logE "at: '$PROJECT_INIT_TESTS_RUN_CONFIG'";
      failure "Failed to execute test run";
    fi
    if [[ $PROJECT_INIT_QUICKSTART_REQUESTED == false ]]; then
      # Adjust path if in test mode
      FORM_QUESTION_ID="project.dir";
      if _get_form_answer; then
        if [[ "$FORM_QUESTION_ANSWER" != "${TESTS_OUTPUT_DIR}"/* ]]; then
          local test_path="${TESTS_OUTPUT_DIR}/${FORM_QUESTION_ANSWER}";
          _FORM_ANSWERS["project.dir"]="$test_path";
        fi
      else
        logE "No project directory specified for test run.";
        logE "Add a 'project.dir' entry in the test run properties file:";
        logE "at: '$PROJECT_INIT_TESTS_RUN_CONFIG'";
        failure "Failed to execute test run";
      fi
    fi
  fi
  # First load the testing project.properties from the addon, then from the
  # base testing resource because those specified there should always take
  # precedence when testing
  if [[ $IS_ADDON_TESTS == true ]]; then
    # shellcheck disable=SC2153
    if [ -r "${TESTPATH}/${_TESTS_PROPERTIES}" ]; then
      _read_properties "${TESTPATH}/${_TESTS_PROPERTIES}";
    fi
  fi
  _read_properties "${BASETESTPATH}/${_TESTS_PROPERTIES}";
}

function main() {
  local testpath="";
  testpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)";
  local rootpath="";
  rootpath=$(dirname "$testpath");
  # Load core libraries
  source "$rootpath/libinit.sh";
  source "$rootpath/libform.sh";

  # Make sure this script is not executed by the root user,
  # except when running inside a Docker container.
  if (( $(id -u) == 0 )); then
    if ! [ -f "/.dockerenv" ]; then
      logW "Cannot run tests as root user";
      return $EXIT_FAILURE;
    fi
  fi

  project_init_start "$@";

  if [[ $PROJECT_INIT_QUICKSTART_REQUESTED == true ]]; then
    project_init_process_quickstart;
  else
    project_init_show_main_form;
    proceed_next_level "$FORM_MAIN_NEXT_DIR";
  fi

  project_init_finish;

  if (( _N_ERRORS > 0 )); then
    logE "";
    local errtitle=" ${COLOR_RED}E R R O R${COLOR_NC} ";
    logE " o-------------------${errtitle}-------------------o";
    logE " |          Test run finished with errors          |";
    logE " o-------------------------------------------------o";
    logE "";
    return $EXIT_FAILURE;
  fi

  local n_warnings=${#_WARNING_LOG[@]};
  if (( n_warnings > 0 || _N_WARNINGS > 0 )); then
    logW "";
    local warningtitle=" ${COLOR_ORANGE}W A R N I N G${COLOR_NC} ";
    logW " o-----------------${warningtitle}-----------------o";
    logW " |         Test run finished with warnings         |";
    logW " o-------------------------------------------------o";
    logW "";
    return $EXIT_FAILURE;
  fi
  return $EXIT_SUCCESS;

}

main "$@";
