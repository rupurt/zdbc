all: test build

test:
	zig build test

build: build.fast
build.fast:
	zig build -Doptimize=ReleaseFast
build.small:
	zig build -Doptimize=ReleaseSmall
build.safe:
	zig build -Doptimize=ReleaseSafe

run:
	zig build run
