ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
EXECUTABLES = git stow
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

update-submodules:
	# Ensure dependencies are up to date
	git submodule update --init

install-generic: update-submodules
	stow -R --no-folding -t ~/ generic

install-work: install-generic
	stow -R --no-folding -t ~/ work

uninstall-generic:
	stow -D --no-folding -t ~/ generic

uninstall-work: uninstall-generic
	stow -D --no-folding -t ~/ work
