ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
EXECUTABLES = git stow
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

install: update-submodules install-config

install-config:
	stow -R --no-folding -t ~/ stow

update-submodules:
	# Ensure dependencies are up to date
	git submodule update --init

uninstall:
	stow -R --no-folding -t ~/ stow
