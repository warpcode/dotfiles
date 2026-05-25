#!/usr/bin/env zsh
worker() { sleep 1; echo "Task $1 at $(date +%s)" }
autoload -Uz zargs
zargs -n 1 -P 2 -- 1 2 -- worker
