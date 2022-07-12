export CGO_ENABLED:=0

VERSION=$(shell git describe --tags --match=v* --always --abbrev=0 --dirty)
LD_FLAGS="-w -X github.com/deploybot-app/github-runner/cmd.version=$(VERSION)"

REPO=github.com/deploybot-app/github-runner
LOCAL_REPO=poseidon/github-runner
IMAGE_REPO=quay.io/poseidon/github-runner

all: image

.PHONY: bin
bin:
	@go build -o bin/gha -ldflags $(LD_FLAGS) $(REPO)/cmd/gha

image: \
	image-amd64 \
	image-arm64

image-%:
	buildah bud -f Dockerfile.$* \
		-t $(LOCAL_REPO):$(VERSION) \
		--layers \
		--arch $* --override-arch $* \
		.
	buildah tag $(LOCAL_REPO):$(VERSION) $(LOCAL_REPO):latest

.PHONY: push
push:
	buildah tag $(LOCAL_REPO):$(VERSION) $(IMAGE_REPO):$(VERSION)
	buildah tag $(LOCAL_REPO):$(VERSION) $(IMAGE_REPO):latest
	buildah push $(IMAGE_REPO):$(VERSION)
	buildah push $(IMAGE_REPO):latest

.PHONY: run
run:
	podman run \
		-it \
		--env-file $(HOME)/.secrets/vault/apps/github-runner/runner.env \
		-v ~/.secrets/vault/apps/github-runner:/etc/github-runner:Z \
		poseidon/github-runner:$(VERSION)
