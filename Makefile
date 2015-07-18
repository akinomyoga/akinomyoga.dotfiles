# -*- mode:makefile-gmake -*-

all:
.PHONY: all install dist

terminfo pkg:
	mkdir -p $@

terminfo/rosaterm.ti: ../terminfo/rosaterm.ti  | terminfo
copyfiles+=terminfo/rosaterm.ti
terminfo/screen-256color.ti: ../terminfo/screen-256color.ti | terminfo
copyfiles+=terminfo/screen-256color.ti

# pkg/mshex.tar.xz: ../src/mshex.20150718.tar.xz | pkg
# copyfiles+=pkg/mshex.tar.xz

pkg/modls.tar.xz: ../src/modls.20141113.tar.xz | pkg
copyfiles+=pkg/modls.tar.xz

screenrc: $(HOME)/.screenrc
copyfiles+=screenrc

$(copyfiles):
	cp -p $< $@
all: $(copyfiles)

install:
	./install.sh

dist:
	cd .. && tar cavf ./myset/dist/myset.$$(date +%Y%m%d).tar.xz ./myset/ --exclude=*~ --exclude=./myset/dist --exclude=./myset/.git
