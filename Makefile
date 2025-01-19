default: build

build:
	zig build --summary all

run:
	@zig build run

clean:
	git clean -dxf

.PHONY: default build run clean
