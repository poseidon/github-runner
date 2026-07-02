export CGO_ENABLED:=0

VERSION=$(shell git describe --tags --match=v* --always)
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
	podman build -f Dockerfile.$* \
		--security-opt seccomp=unconfined \
		-t $(LOCAL_REPO):$(VERSION)-$* \
		--layers \
		--platform linux/$* \
		.

push-%:
	podman tag $(LOCAL_REPO):$(VERSION)-$* $(IMAGE_REPO):$(VERSION)-$*
	podman push $(IMAGE_REPO):$(VERSION)-$*

manifest:
	podman manifest create $(IMAGE_REPO):$(VERSION)
	podman manifest add $(IMAGE_REPO):$(VERSION) docker://$(IMAGE_REPO):$(VERSION)-amd64
	podman manifest add $(IMAGE_REPO):$(VERSION) docker://$(IMAGE_REPO):$(VERSION)-arm64
	podman manifest inspect $(IMAGE_REPO):$(VERSION)
	podman manifest push $(IMAGE_REPO):$(VERSION) docker://$(IMAGE_REPO):$(VERSION)

.PHONY: run
run:
	podman run \
		-it \
		--env-file ~/.config/github-runner/poseidon.env \
		-v $(shell readlink -f ~/.config/github-runner/poseidon.env):/etc/github-runner/dghubble-org.env \
		-v $(shell readlink -f ~/.config/github-runner/github-app.key.pem):/etc/github-runner/github-app.key.pem \
		localhost/poseidon/github-runner:$(VERSION)-amd64
