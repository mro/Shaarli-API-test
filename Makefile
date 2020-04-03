#
# https://github.com/ocaml/dune/tree/master/example/sample-projects/hello_world
# via https://stackoverflow.com/a/54712669
#
.PHONY: all build clean test install uninstall doc examples

final: build _build/pinboard.cgi

build:
	@echo "let git_sha = \""`git rev-parse --short HEAD`"\"" > bin/version.ml
	@echo "let date = \""`date`"\""                         >> bin/version.ml
	dune build bin/pinboard.exe

all: build

test:
	dune runtest

examples:
	dune build @examples

install:
	dune install

uninstall:
	dune uninstall

doc:
	dune build @doc

clean:
	rm -rf _build *.install


_build/pinboard.cgi: _build/default/bin/pinboard.exe
	cp $< $@
	chmod u+w $@
	strip $@
	ls -l $@

