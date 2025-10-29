ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

update-submodules:
	# Ensure dependencies are up to date
	git submodule update --init --remote

install-generic: update-submodules
	stow -R --no-folding -t ~/ generic

install-work: install-generic
	stow -R --no-folding -t ~/ work

uninstall-generic:
	stow -D --no-folding -t ~/ generic

uninstall-work: uninstall-generic
	stow -D --no-folding -t ~/ work
