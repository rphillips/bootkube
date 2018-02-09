export GO15VENDOREXPERIMENT:=1
export CGO_ENABLED:=0
export GOARCH:=amd64

SHELL:=$(shell which bash)
LOCAL_OS:=$(shell uname | tr A-Z a-z)
GOFILES:=$(shell find . -name '*.go' | grep -v -E '(./vendor)')
GOPATH_BIN:=$(shell echo ${GOPATH} | awk 'BEGIN { FS = ":" }; { print $1 }')/bin
LDFLAGS=-X github.com/kubernetes-incubator/bootkube/pkg/version.Version=$(shell $(CURDIR)/build/git-version.sh)

GOLANG:=golang:1.9.4
TERRAFORM:=hashicorp/terraform:0.11.3
DEP:=instrumentisto/dep:0.4.1
DOCKER_OPTS:=-v $(PWD):/go/src/github.com/kubernetes-incubator/bootkube -w /go/src/github.com/kubernetes-incubator/bootkube 

all: \
	_output/bin/$(LOCAL_OS)/bootkube \
	_output/bin/linux/bootkube \
	_output/bin/linux/checkpoint

cross: \
	_output/bin/linux/bootkube \
	_output/bin/darwin/bootkube \
	_output/bin/linux/checkpoint \
	_output/bin/linux/amd64/checkpoint \
	_output/bin/linux/arm/checkpoint \
	_output/bin/linux/arm64/checkpoint \
	_output/bin/linux/ppc64le/checkpoint \
	_output/bin/linux/s390x/checkpoint

release: \
	clean \
	check \
	_output/release/bootkube.tar.gz \

check:
	@docker run $(DOCKER_OPTS) $(GOLANG) gofmt -l -s $(GOFILES) | read; if [ $$? == 0 ]; then gofmt -s -d $(GOFILES); exit 1; fi
	@docker run $(DOCKER_OPTS) $(TERRAFORM) fmt -check ; if [ ! $$? -eq 0 ]; then exit 1; fi
	@docker run $(DOCKER_OPTS) $(GOLANG) go vet $(shell go list ./... | grep -v '/vendor/') 
	@docker run $(DOCKER_OPTS) $(GOLANG) ./scripts/verify-gopkg.sh
	@docker run $(DOCKER_OPTS) $(GOLANG) go test -v $(shell go list ./... | grep -v '/vendor/\|/e2e')

install: _output/bin/$(LOCAL_OS)/bootkube
	cp $< $(GOPATH_BIN)

_output/bin/%: GOOS=$(word 1, $(subst /, ,$*))
_output/bin/%: GOARCH=$(word 2, $(subst /, ,$*))
_output/bin/%: GOARCH:=amd64  # default to amd64 to support release scripts
_output/bin/%: $(GOFILES)
	mkdir -p $(dir $@)
	GOOS=$(GOOS) GOARCH=$(GOARCH) docker run --rm $(DOCKER_OPTS) $(GOLANG) go build $(GOFLAGS) -ldflags "$(LDFLAGS)" -o $@ github.com/kubernetes-incubator/bootkube/cmd/$(notdir $@)

_output/release/bootkube.tar.gz: _output/bin/linux/bootkube _output/bin/darwin/bootkube _output/bin/linux/checkpoint
	mkdir -p $(dir $@)
	tar czf $@ -C _output bin/linux/bootkube bin/darwin/bootkube bin/linux/checkpoint

run-%: GOFLAGS = -i
run-%: clean-vm-% _output/bin/linux/bootkube _output/bin/$(LOCAL_OS)/bootkube
	@cd hack/$*-node && ./bootkube-up
	@echo "Bootkube ready"

clean-vm-single:
clean-vm-%:
	@echo "Cleaning VM..."
	@(cd hack/$*-node && \
	    vagrant destroy -f && \
	    rm -rf cluster )

#TODO(aaron): Prompt because this is destructive
conformance-%: clean all
	@cd hack/$*-node && vagrant destroy -f
	@cd hack/$*-node && rm -rf cluster
	@cd hack/$*-node && ./bootkube-up
	@sleep 30 # Give addons a little time to start
	@cd hack/$*-node && ./conformance-test.sh

vendor:
	@docker run $(DOCKER_OPTS) $(DEP) ensure
	@docker run $(DOCKER_OPTS) $(GOLANG) -o _output/bin/license-bill-of-materials ./vendor/github.com/coreos/license-bill-of-materials
	@docker run $(DOCKER_OPTS) $(GOLANG) ./_output/bin/license-bill-of-materials ./cmd/bootkube ./cmd/checkpoint > bill-of-materials.json

clean:
	rm -rf _output

.PHONY: all check clean install release vendor
