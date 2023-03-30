SRC_DIR := src

.PHONY=all
all:
	elm make

.PHONY=watch
watch:
	@find ${SRC_DIR} -name '*.elm' | entr $(MAKE)


