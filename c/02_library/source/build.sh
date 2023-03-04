#!/bin/bash
# Build script for the ${{VAR_PROJECT_NAME}} library.

USAGE="Usage: build.sh [options]";

HELP_TEXT=$(cat << EOS
Builds the ${{VAR_PROJECT_NAME}} library.

${USAGE}

Options:

  [--clean]      Remove all build-related directories and files and then exit.

  [--debug]      Build the libraries with debug symbols and with
                 optimizations turned off.
${{VAR_SCRIPT_BUILD_ISOLATED_OPT}}

  [--shared]     Build shared libraries instead of static libraries.

  [--skip-tests] Do not build any tests.

  [-?|--help]    Show this help message.
EOS
)

# Arg flags
ARG_CLEAN=false;
ARG_SHARED=false;
ARG_DEBUG=false;
${{VAR_SCRIPT_BUILD_ISOLATED_ARGFLAG}}
ARG_SKIP_TESTS=false;
ARG_SHOW_HELP=false;

${{VAR_SCRIPT_BUILD_ISOLATED_ARGARRAY}}

# Parse all arguments given to this script
for arg in "$@"; do
  case $arg in
    --clean)
    ARG_CLEAN=true;
    shift
    ;;
    --shared)
    ARG_SHARED=true;
${{VAR_SCRIPT_BUILD_ISOLATED_ARGARRAY_ADD}}
    shift
    ;;
    --debug)
    ARG_DEBUG=true;
${{VAR_SCRIPT_BUILD_ISOLATED_ARGARRAY_ADD}}
    shift
    ;;
    --skip-tests)
    ARG_SKIP_TESTS=true;
${{VAR_SCRIPT_BUILD_ISOLATED_ARGARRAY_ADD}}
    shift
    ;;
${{VAR_SCRIPT_BUILD_ISOLATED_ARGPARSE}}
    -\?|--help)
    ARG_SHOW_HELP=true;
    shift
    ;;
    *)
    # Unknown Argument
    echo "Unknown argument: '$arg'";
    echo "$USAGE";
    echo "";
    echo "Run 'build.sh --help' for more information";
    exit 1;
    ;;
  esac
done

# Check if help is triggered
if [[ $ARG_SHOW_HELP == true ]]; then
  echo "$HELP_TEXT";
  exit 0;
fi

# Check clean flag
if [[ $ARG_CLEAN == true ]]; then
  if [ -d "build" ]; then
    rm -rf "build";
  fi
  exit 0;
fi

if ! [ -d "build" ]; then
  mkdir "build";
fi

${{VAR_SCRIPT_BUILD_ISOLATED_MAIN}}

# Ensure the required executable is available
if ! command -v "cmake" &> /dev/null; then
  echo "ERROR: Could not find the 'cmake' executable.";
  echo "Please make sure that CMake is correctly installed";
${{VAR_SCRIPT_BUILD_ISOLATED_HINT1}}
  exit 1;
fi

cd "build";

BUILD_CONFIGURATION="Release";

if [[ $ARG_DEBUG == true ]]; then
  BUILD_CONFIGURATION="Debug";
fi

BUILD_TESTS="ON";

if [[ $ARG_SKIP_TESTS == true ]]; then
  BUILD_TESTS="OFF";
fi

BUILD_SHARED_LIBS="OFF";

if [[ $ARG_SHARED == true ]]; then
  BUILD_SHARED_LIBS="ON";
fi

# CMake: Configure
cmake -DCMAKE_BUILD_TYPE="$BUILD_CONFIGURATION" \
      -D${{VAR_PROJECT_NAME_UPPER}}_BUILD_TESTS="$BUILD_TESTS" \
      -D${{VAR_PROJECT_NAME_UPPER}}_BUILD_SHARED_LIBS="$BUILD_SHARED_LIBS" .. ;

if (( $? != 0 )); then
  exit $?;
fi

# CMake: Build
cmake --build . --config "$BUILD_CONFIGURATION";
exit $?;
