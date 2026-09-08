# Native Linux/X11 toolchain, shared by the Rasta library and tests.
DOCKER_RASTA ?= libgpx-rasta:local
DOCKER_USER ?= $(shell id -u):$(shell id -g)
RASTA_RUN = docker run --rm --init -u $(DOCKER_USER) \
	-v "$(ROOT_DIR)":/work -w /work $(DOCKER_RASTA)

.PHONY: rasta-docker
rasta-docker:
	docker build -q -t $(DOCKER_RASTA) -f $(ROOT_DIR)/scripts/docker/rasta.Dockerfile $(ROOT_DIR)/scripts/docker
