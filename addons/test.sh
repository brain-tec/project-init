#!/bin/bash
# Test script for a Project Init addon.

# The bootstrap run script.
# Makes the Project Init base resource available
PROJECT_INIT_BOOTSTRAP_RUN="https://github.com/raven-computing/project-init/raw/v1-latest/bootstrap/run.sh";

USAGE="Usage: test.sh [options]";

HELP_TEXT=$(cat << EOS
Tests the Project Init addon.

${USAGE}

Run this script to perform functionality tests for this addon.
If no arguments are given, all available functionality tests are run.

Options:

  [-f|--filter]   TESTS
                  Only run the specified functionality tests.
                  The mandatory option argument TESTS must specify a comma-separated list
                  of test case names. Only those functionality test cases will be executed.
                  For example, specifying '-f java_example_app' will only execute the test
                  provided by the 'tests/test_func_java_example_app.sh' file.

  [--keep-output] Do not automatically remove files generated by functionality tests.
                  Subsequent runs will still remove any residue files prior to
                  the next execution.

  [-?|--help]     Show this help message.
EOS
)

# Arg flags
ARG_TEST_FILTER=false;
ARG_KEEP_OUTPUT=false;
ARG_SHOW_HELP=false;

# Arg helper vars
arg_check_optarg=false;
arg_optarg_key="";
arg_optarg_required="";
TEST_ARGS=();

# Parse all arguments given to this script
for arg in "$@"; do
  if [[ $arg_check_optarg == true ]]; then
    arg_check_optarg=false;
    if [[ "$arg" != -* ]]; then
      TEST_ARGS+=("$arg");
      arg_optarg_required="";
      shift;
      continue;
    fi
  fi
  if [ -n "$arg_optarg_required" ]; then
    echo "Missing required option argument '$arg_optarg_required'";
    exit 1;
  fi
  case $arg in
    -f|--filter)
    ARG_TEST_FILTER=true;
    arg_check_optarg=true;
    TEST_ARGS+=("--functionality");
    arg_optarg_required="TESTS";
    shift
    ;;
    --keep-output)
    ARG_KEEP_OUTPUT=true;
    TEST_ARGS+=("--keep-output");
    shift
    ;;
    -\?|--help)
    ARG_SHOW_HELP=true;
    shift
    ;;
    *)
    # Unknown Argument
    echo "Unknown argument: '$arg'";
    echo "$USAGE";
    echo "";
    echo "Run 'test.sh --help' for more information";
    exit 1;
    ;;
  esac
done

# Check if help is triggered
if [[ $ARG_SHOW_HELP == true ]]; then
  echo "$HELP_TEXT";
  exit 0;
fi

if [ -n "$arg_optarg_required" ]; then
  echo "Missing required option argument '$arg_optarg_required'";
  exit 1;
fi

# Download the bootstrap code. Try with wget and curl
if command -v "wget" &> /dev/null; then
  bootstrap_code=$(wget -q -O - $PROJECT_INIT_BOOTSTRAP_RUN);
elif command -v "curl" &> /dev/null; then
  bootstrap_code=$(curl -sL $PROJECT_INIT_BOOTSTRAP_RUN);
else
  echo "ERROR: Cannot fetch Project Init bootstrap code";
  echo "Neither 'wget' nor 'curl' command is available";
  exit 1;
fi

if (( $? != 0 )); then
  echo "ERROR: Failed fetch Project Init bootstrap code";
  exit 1;
fi

# Instruct the bootstrap run script to only make the resources of Project Init
# available and print the location to stdout, and not start the tool directly.
export PROJECT_INIT_BOOTSTRAP_FETCHONLY="1";

# Run the bootstrap code and capture the output
bootstrap_output=$(echo "$bootstrap_code" |bash);
if (( $? != 0 )); then
  echo "ERROR: Failed to make Project Init base resources available";
  if [ -n "$bootstrap_output" ]; then
    echo "The bootstrap program failed with output:";
    echo "$bootstrap_output";
  fi
  exit 1;
fi

# If no errors occurred, the bootstrap script has printed the path to
# the cached Project Init base resources to stdout
PROJECT_INIT_BASE_LOCATION="$bootstrap_output";

# The path to the addons source root
test_path="$PWD";

# Handle any additional args
ftest_args="";
if (( ${#TEST_ARGS[@]} > 0 )); then
  ftest_args="${TEST_ARGS[@]}";
fi

# Run the Project Init test.sh script and tell it to scan
# our tests instead of the base tests
bash "$PROJECT_INIT_BASE_LOCATION/test.sh" --test-path "$test_path" $ftest_args;

exit $?;