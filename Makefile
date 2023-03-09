ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
EXECUTABLES = git stow
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

install: update-submodules install-config

install-work: install install-config-work

install-config:
	stow -R --no-folding -t ~/ stow

install-config-work:
	stow -R --no-folding -t ~/ stow-work

update-submodules:
	# Ensure dependencies are up to date
	git submodule update --init

uninstall: uninstall-work
	stow -D --no-folding -t ~/ stow

uninstall-work:
	stow -D --no-folding -t ~/ stow-work
