ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

install-deps:
	bash install-deps.sh

update-submodules:
	# Ensure dependencies are up to date
	git submodule update --init --remote

install-generic: install-deps update-submodules
	stow -R --no-folding -t ~/ generic

install-work: install-generic
	stow -R --no-folding -t ~/ work

uninstall-generic:
	stow -D --no-folding -t ~/ generic

uninstall-work: uninstall-generic
	stow -D --no-folding -t ~/ work
