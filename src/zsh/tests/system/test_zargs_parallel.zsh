#!/usr/bin/env zsh
# test_zargs_parallel.zsh - Verify parallel execution of shell functions via zargs.

worker() { 
    sleep 1
    echo "Task $1 at $(date +%s)" 
}

# Ensure we are in a Zsh environment and zargs is available
autoload -Uz zargs

print "Starting parallel tasks..."
zargs -n 1 -P 2 -- 1 2 -- worker
