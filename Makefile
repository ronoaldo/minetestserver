SHELL=bash
IMAGE=ghcr.io/ronoaldo/minetestserver
TAG=latest

build:
	docker build -t ${IMAGE}:${TAG} .

run: build
	docker run --rm --name minetestserver -it -P ${IMAGE}:${TAG}

build-workflow-matrix:
	@for i in $$(seq 0 1) ; do \
		MATRIX="$$(yq -r ".jobs.\"multiarch-build\".strategy.matrix.include[$$i] | .args" \
			< .github/workflows/multiarch.yaml)" ;\
		while read arg ; do export ARGS="$${ARGS} --build-arg $${arg}" ; done <<<"$${MATRIX}"; \
		docker buildx build \
			$${ARGS} \
			--file Dockerfile \
			--platform linux/amd64 \
			. ; \
	done
