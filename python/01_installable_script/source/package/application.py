${{VAR_COPYRIGHT_HEADER}}
"""Installable script main entry point."""

import sys


def main(argv: list[str]) -> int:
    """Main function of the ${{VAR_PROJECT_NAME}} application.

    Args:
        argv (list): The list of str program arguments.

    Returns:
        int: The exit code of the program.
    """
    print("${{VAR_PROJECT_SLOGAN_STRING}}")
    if len(argv) > 1:
        print("Args: " + str(argv[1:]))

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
