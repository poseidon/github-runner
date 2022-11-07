export CGO_ENABLED:=0

VERSION=$(shell git describe --tags --match=v* --always --dirty)
LD_FLAGS="-w -X github.com/poseidon/github-runner/cmd.version=$(VERSION)"

REPO=github.com/poseidon/github-runner
LOCAL_REPO=poseidon/github-runner
IMAGE_REPO=quay.io/poseidon/github-runner

.PHONY: all
all: bin test vet fmt

.PHONY: bin
bin:
	@go build -o bin/gha -ldflags $(LD_FLAGS) $(REPO)/cmd/gha

.PHONY: test
test:
	@go test ./... -cover

.PHONY: vet
vet:
	@go vet -all ./...

.PHONY: fmt
fmt:
	@test -z $$(go fmt ./...)

image: \
	image-amd64 \
	image-arm64

image-%:
	buildah bud -f Dockerfile.$* \
		-t $(LOCAL_REPO):$(VERSION)-$* \
		--layers \
		--arch $* --override-arch $* \
		.

.PHONY: run
run:
	podman run \
		-it \
		--env-file $(HOME)/.secrets/vault/apps/github-runner/runner.env \
		-v ~/.secrets/vault/apps/github-runner:/etc/github-runner:Z \
		poseidon/github-runner:$(VERSION)
