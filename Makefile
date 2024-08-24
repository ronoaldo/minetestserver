IMAGE=ghcr.io/ronoaldo/minetestserver
TAG=latest

build:
	docker build -t ${IMAGE}:${TAG} .

run: build
	docker run --rm --name minetestserver -it -P ${IMAGE}:${TAG}
