REPOSITORY ?= dintero/docker-postgres-pgaudit
TAG ?= $(REPOSITORY):latest
POSTGRES_VERSION := $(shell grep -oE 'POSTGRES_VERSION=[^ ]+' Dockerfile | cut -d= -f2)
PUBLISH_TAGS ?= $(REPOSITORY):latest $(REPOSITORY):$(POSTGRES_VERSION)
DOCKER_BUILDKIT ?= 1
PLATFORMS ?= linux/amd64,linux/arm64
BUILDX_CACHE_ARGS ?=

build:
	docker buildx build --platform $(PLATFORMS) --tag $(TAG) $(BUILDX_CACHE_ARGS) .

publish:
	docker buildx build --platform $(PLATFORMS) $(addprefix --tag ,$(PUBLISH_TAGS)) $(BUILDX_CACHE_ARGS) --push .

test:
	docker rm -f pgaudit-test >/dev/null 2>&1 || true
	@sh -c '\
		trap "docker rm -f pgaudit-test >/dev/null 2>&1" EXIT; \
		docker run -d --name pgaudit-test -e POSTGRES_PASSWORD=test $(TAG) -c shared_preload_libraries=pgaudit; \
		i=0; \
		until docker exec pgaudit-test pg_isready -U postgres >/dev/null 2>&1; do \
			i=$$((i+1)); \
			if [ $$i -ge 30 ]; then echo "timed out waiting for postgres"; docker logs pgaudit-test; exit 1; fi; \
			sleep 1; \
		done; \
		docker exec pgaudit-test psql -U postgres -c "CREATE EXTENSION pgaudit;"; \
		docker exec pgaudit-test psql -U postgres -c "SHOW pgaudit.log;"; \
	'

install: build test
