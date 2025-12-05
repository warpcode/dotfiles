if (( $+commands[python3] )); then
    export _W_PYTHON_COMMAND="${_W_PYTHON_COMMAND:-python3}"
elif (( $+commands[python] )); then
    export _W_PYTHON_COMMAND="${_W_PYTHON_COMMAND:-python}"
fi
