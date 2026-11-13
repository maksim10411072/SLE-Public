LUA ?= luajit
ARGS ?=
.PHONY: example/% examples
example/%: examples/%.lua
	$(LUA) $< $(ARGS)
examples:
	@echo "Available examples:"
	@echo "---"
	@ls examples | sed -e "s/\.lua//"
	@echo "---"
	@echo "Use make example/<name> to run example, add ARGS=<args> for arguments for that example and LUA=<lua> to change lua command."
	@echo "Default is luajit"