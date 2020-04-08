
cpu	:= $(shell uname -m)
os	:= $(shell uname -s)
ver	:= 0.1
dst := _build/pin4sha-$(os)-$(cpu)-$(ver).cgi

final: build $(dst)

res/doap.rdf.gz:	doap.rdf
	gzip --best < $< > $@

res/doap2html.xslt.gz:	doap2html.xslt
	gzip --best < $< > $@

res/v1/openapi.yaml.gz: openapi.yaml
	gzip --best < $< > $@

lib/res.ml:	res res/doap.rdf.gz res/doap2html.xslt.gz res/v1/openapi.yaml.gz
	# opam install ocp-ocamlres
	find res -name .DS_Store -delete
	ocp-ocamlres -format ocaml $< -o $@

#
# https://github.com/ocaml/dune/tree/master/example/sample-projects/hello_world
# via https://stackoverflow.com/a/54712669
#
.PHONY: all build clean test install uninstall doc examples

build: lib/res.ml
	@echo "let git_sha = \""`git rev-parse --short HEAD`"\"" > bin/version.ml
	@echo "let date = \""`date +'%FT%T%z'`"\""              >> bin/version.ml
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
	rm -rf lib/res.ml _build *.install


$(dst): _build/default/bin/pinboard.exe
	cp $< $@
	chmod u+w $@
	strip $@
	ls -l $@

