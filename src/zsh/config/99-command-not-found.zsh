function command_not_found_handler() {
    # Check docker images


    # If nothing is found, show original error
    echo "zsh: command not found: $1";
    return 127
}
