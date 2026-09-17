.PHONY: all build run universal clean

all: build

build:
	./script/build_and_run.sh --build-only

run:
	./script/build_and_run.sh

universal:
	./script/build_and_run.sh --universal

clean:
	@rm -rf ./build
