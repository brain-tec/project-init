#!/bin/bash
###############################################################################
#                                                                             #
#       Project Control Code to Build and Test in Isolated Environments       #
#                                                                             #
# This shell script provides functions to handle isolated executions          #
# via Docker. Users may source this file and call the provided functions to   #
# either build or test the underlying project inside a Docker container.      #
# This can also be used to run arbitrary commands inside an isolated          #
# container or to get an interactive shell. Some execution parameters         #
# can be controlled by setting various PROJECT_CONTAINER_* variables.         #
#                                                                             #
###############################################################################

# The Dockerfile to be used for creating images for isolated builds
PROJECT_CONTAINER_BUILD_DOCKERFILE="Dockerfile-build";
# The name given to the image and container
PROJECT_CONTAINER_BUILD_NAME="${{VAR_PROJECT_NAME_LOWER}}-build";
# The version tag given to the image and container
PROJECT_CONTAINER_BUILD_VERSION="0.1";

# The docker-compose file to be used for isolated interactive tests
PROJECT_CONTAINER_TEST_DOCKER_COMPOSE="docker-compose-test.yaml";


# Executes an isolated command inside a Docker container.
#
# This function builds the image, creates a container from it
# and then runs that container. The container is removed after
# the execution has completed.
#
# The building of the Docker image can be suppressed by setting the
# environment variable PROJECT_CONTAINER_IMAGE_BUILD to the value "0".
#
# Args:
# $@ - The arguments to be passed to the container's entrypoint.
#
# Returns:
# Either the exit status of the Docker-related commands, if unsuccessful,
# or the exit status of the specified command.
#
function project_run_isolated() {
  local isolated_command="$1";
  shift;
  if ! command -v "docker" &> /dev/null; then
    logE "ERROR: Could not find the 'docker' executable.";
    logE "If you want a command to be executed in an isolated environment,";
    logE "please make sure that Docker is correctly installed";
    return 1;
  fi

  local uid=0;
  local gid=0;
  local workdir_name="${{VAR_PROJECT_NAME_LOWER}}";
  local workdir="/root/${workdir_name}";
  # When using non-rootless Docker, the user inside the container should be a
  # regular user. We assign him the same UID and GID as the underlying host
  # user so that there are no conflicts when bind-mounting the source tree.
  # However, when rootless Docker is used, we want to use the root user inside
  # the container as it essentially maps to the underlying host user from
  # a security point of view.
  if ! docker info 2>/dev/null |grep -q "rootless"; then
    uid=$(id -u);
    gid=$(id -g);
    workdir="/home/user/${workdir_name}";
  fi
  local name_tag="${PROJECT_CONTAINER_BUILD_NAME}:${PROJECT_CONTAINER_BUILD_VERSION}";
  if [[ "$PROJECT_CONTAINER_IMAGE_BUILD" != "0" ]]; then
    logI "Building Docker image";
    docker build --build-arg UID=${uid}                                \
                 --build-arg GID=${gid}                                \
                 --build-arg DWORKDIR="${workdir}"                     \
                 --tag "$name_tag"                                     \
                 --file .docker/${PROJECT_CONTAINER_BUILD_DOCKERFILE} .

    local docker_status=$?;
    if (( docker_status != 0 )); then
      return $docker_status;
    fi
  fi

  logI "Executing isolated $isolated_command";
  docker run --name ${PROJECT_CONTAINER_BUILD_NAME}                \
             --mount type=bind,source="${PWD}",target="${workdir}" \
             --user ${uid}:${gid}                                  \
             --rm                                                  \
             --tty                                                 \
             --interactive                                         \
             "$name_tag"                                           \
             "$isolated_command"                                   \
             "$@";

  return $?;
}

# Executes an isolated odoo process inside a Docker container.
#
# This function can be used to create an isolated Odoo instance and a
# corresponding data base using Docker Compose.
#
# Args:
# $@ - Arguments to be passed to the odoo executable at startup.
#
# Returns:
# The exit status of the Docker-related command. If the Docker command is
# successful, then the exit status of the executed odoo command is
# returned instead.
#
function _start_interactive_isolated_tests() {
  if ! command -v "docker" &> /dev/null; then
    logE "ERROR: Could not find the 'docker' executable.";
    logE "If you want to create an isolated environment for interactive testing,";
    logE "please make sure that Docker and Docker Compose are correctly installed";
    return 1;
  fi
  logI "Starting isolated Docker containers for interactive testing";
  docker compose --file .docker/${PROJECT_CONTAINER_TEST_DOCKER_COMPOSE} \
                 --project-directory "${PWD}"                            \
                 run                                                     \
                 --service-ports                                         \
                 web                                                     \
                 "$@";

  return $?;
}

# Executes an isolated test process inside a Docker container.
#
# This function is used for two purposes. It either executes a 'docker build'
# followed by a 'docker run' command used to run the project's test suite, or
# it starts an interactive test session, allowing the user to interact with a
# running Odoo instance and test functionality. All actions are executed in
# in an isolated Docker container.
#
# An interactive test session is requested by specifying
# the --interactive option, potentially followed by odoo command arguments
# for the isolated environment.
#
# Args:
# $@ - Arguments to be passed to the project's test.sh script to customise the
#      test process, or the arguments to be passed to the odoo command when
#      using an interactive test session.
#
# Returns:
# The exit status of the Docker-related commands. If the Docker commands are
# all successful, then the exit status of the executed test.sh script
# is returned instead.
# Returns the exit status of the odoo process when using an
# interactive test session.
#
function project_run_isolated_tests() {
  local arg="";
  local run_interactive_session=false;
  local odoo_args=();
  # List of arguments not to pass to Odoo when testing interactively
  local args_it_ignore="^(--no-virtualenv)$";

  for arg in "$@"; do
    if [[ $run_interactive_session == true ]]; then
      if ! [[ "$arg" =~ $args_it_ignore ]]; then
        odoo_args+=($arg);
      fi
    elif [[ "$arg" == "--interactive" ]]; then
      run_interactive_session=true;
   fi
  done

  if [[ $run_interactive_session == true ]]; then
    _start_interactive_isolated_tests "${odoo_args[@]}";
  else
    project_run_isolated "tests" "$@";
  fi
  return $?;
}
