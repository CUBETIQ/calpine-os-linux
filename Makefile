DOCKER_IMAGE_NAME = cubetiq/calpine-os-linux
DOCKER_IMAGE_SIZE = $(shell docker images --format "{{.Repository}} {{.Size}}" | grep $(DOCKER_IMAGE_NAME) | cut -d\   -f2)

build:
	./src/build.sh
	@echo "Size of the image: ${DOCKER_IMAGE_SIZE}"

	docker tag ${DOCKER_IMAGE_NAME}:3.13 ${DOCKER_IMAGE_NAME}:latest
	docker push ${DOCKER_IMAGE_NAME}

.PHONY: build
