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
		--security-opt seccomp=unconfined \
		-t $(LOCAL_REPO):$(VERSION)-$* \
		--layers \
		--arch $* --override-arch $* \
		.

push-%:
	buildah tag $(LOCAL_REPO):$(VERSION)-$* $(IMAGE_REPO):$(VERSION)-$*
	buildah push --format v2s2 $(IMAGE_REPO):$(VERSION)-$*

manifest:
	buildah manifest create $(IMAGE_REPO):$(VERSION)
	buildah manifest add $(IMAGE_REPO):$(VERSION) docker://$(IMAGE_REPO):$(VERSION)-amd64
	buildah manifest add --variant v8 $(IMAGE_REPO):$(VERSION) docker://$(IMAGE_REPO):$(VERSION)-arm64
	buildah manifest inspect $(IMAGE_REPO):$(VERSION)
	buildah manifest push -f v2s2 $(IMAGE_REPO):$(VERSION) docker://$(IMAGE_REPO):$(VERSION)

.PHONY: run
run:
	podman run \
		-it \
		--env-file ~/.config/github-runner/github-runner.env \
		-v ~/.config/github-runner:/etc/github-runner:Z \
		-v /run:/run \
		localhost/poseidon/github-runner:$(VERSION)-amd64
