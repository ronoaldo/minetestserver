SHELL=bash
IMAGE=ghcr.io/ronoaldo/luantiserver
TAG=latest

build:
	docker build -t ${IMAGE}:${TAG} .

run: build
	docker run --rm --name luantiserver -it \
		--publish 30000:30000/udp \
		--publish 30000:30000/tcp ${IMAGE}:${TAG}

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
