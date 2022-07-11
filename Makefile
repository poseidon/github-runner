export CGO_ENABLED:=0

VERSION=$(shell git describe --tags --match=v* --always --abbrev=0 --dirty)
LD_FLAGS="-w -X github.com/deploybot-app/github-runner/cmd.version=$(VERSION)"

REPO=github.com/deploybot-app/github-runner
LOCAL_REPO=poseidon/github-runner
IMAGE_REPO=quay.io/poseidon/github-runner

GITHUB_RUNNER=2.294.0
SHA=a19a09f4eda5716e5d48ba86b6b78fc014880c5619b9dba4a059eaf65e131780

all: image

.PHONY: bin
bin:
	@go build -o bin/gha -ldflags $(LD_FLAGS) $(REPO)/cmd/gha

.PHONY: image
image:
	buildah bud -t $(LOCAL_REPO):$(VERSION) \
		--layers \
		--build-arg VERSION=$(GITHUB_RUNNER) \
		--build-arg SHA=$(SHA) \
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
