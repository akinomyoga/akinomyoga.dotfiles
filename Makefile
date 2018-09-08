# -*- mode: makefile-gmake -*-

all:
.PHONY: all

.PHONY: install
install:
	bash make_command.sh install

.PHONY: sort-aspell
sort-aspell:
	bash make_command.sh sort-aspell-dictionary
