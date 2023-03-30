SRC_DIR := src
BUILD_DIR := dist
ELM_JS := elm.js
ELM_MAKE_FLAGS:= --debug

${BUILD_DIR}/${ELM_JS}: ${SRC_DIR}/Main.elm ${SRC_DIR}/*.elm
	@echo "Compiling $@ from $<"
	elm make $< --output=$@ $(ELM_MAKE_FLAGS)

.PHONY=watch
watch:
	@find ${SRC_DIR} -name '*.elm' | entr $(MAKE)
