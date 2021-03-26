DOCKER_IMAGE_NAME = calpine-os-linux
DOCKER_IMAGE_VERSION = 3.13.3
DOCKER_IMAGE_SIZE = $(shell docker images --format "{{.Repository}} {{.Size}}" | grep $(DOCKER_IMAGE_NAME) | cut -d\   -f2)

build:
	$(shell ./src/build.sh)
	@echo "Size of the image: ${DOCKER_IMAGE_SIZE}"

.PHONY: build