
generate:
	tree-sitter generate

test: generate
	tree-sitter test

build_parser: generate
	cc -o ./build/parser.so -I./src src/parser.c src/scanner.cc -shared -Os -lstdc++ -fPIC
