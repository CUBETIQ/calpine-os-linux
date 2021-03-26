DOCKER_IMAGE_NAME = cubetiq/calpine-os-linux
DOCKER_IMAGE_SIZE = $(shell docker images --format "{{.Repository}} {{.Size}}" | grep $(DOCKER_IMAGE_NAME) | cut -d\   -f2)

build:
	./src/build.sh
	@echo "Size of the image: ${DOCKER_IMAGE_SIZE}"

	docker push ${DOCKER_IMAGE_NAME}

.PHONY: build
