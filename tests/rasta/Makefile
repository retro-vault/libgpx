.DEFAULT_GOAL := tests
ROOT_DIR ?= $(abspath ../..)
include $(ROOT_DIR)/scripts/mk/rasta.mk
ADVANCED ?= 1

.PHONY: tests
tests: rasta-docker
	$(RASTA_RUN) python3 tests/rasta/run-tests.py $(ADVANCED)
	$(MAKE) -C $(ROOT_DIR)/src/rasta demo
	$(RASTA_RUN) env SDL_VIDEODRIVER=x11 SDL_RENDER_DRIVER=software xvfb-run -a -s '-screen 0 1920x1080x24' python3 scripts/run/run-rasta-session.py --smoke
