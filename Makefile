#
#   Copyright 2015  Xebia Nederland B.V.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
REGISTRY_HOST=docker.io
USERNAME=$(USER)
NAME=$(shell basename $(PWD))

RELEASE_SUPPORT=./.make-release-support
IMAGE=$(REGISTRY_HOST)/$(USERNAME)/$(NAME)

VERSION=$(shell . $(RELEASE_SUPPORT) ; getVersion)
TAG=$(shell . $(RELEASE_SUPPORT); getTag)

SHELL=/bin/bash

.PHONY: pre-build docker-build post-build build release patch-release minor-release major-release tag check-status check-release showver

build: pre-build docker-build post-build

pre-build:


post-build:


docker-build: .release
	docker build -t $(IMAGE):$(VERSION) .
	docker tag  -f $(IMAGE):$(VERSION) $(IMAGE):latest

.release: 
	@echo "release=0.0.0" > .release
	@echo "tag=$(NAME)-0.0.0" >> .release
	@echo INFO: .release created
	@cat .release

release: check-status check-release build
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):latest

showver: .release
	@. $(RELEASE_SUPPORT); getVersion

patch-release: VERSION = $(shell . $(RELEASE_SUPPORT); nextPatchLevel)
patch-release: tag release

minor-release: VERSION = $(shell . $(RELEASE_SUPPORT); nextMinorLevel)
minor-release: tag release

major-release: VERSION = $(shell . $(RELEASE_SUPPORT); nextMajorLevel)
major-release: tag release

tag: TAG=$(shell . $(RELEASE_SUPPORT); getTag $(VERSION))
tag: check-status
	@. $(RELEASE_SUPPORT) ; ! tagExists $(TAG) || (echo "ERROR: tag $(TAG) for version $(VERSION) already tagged in git" >&2 && exit 1) ;
	@. $(RELEASE_SUPPORT) ; setRelease $(VERSION)
	git add .release
	git commit -m "bumped to version $(VERSION)" ;
	git tag $(TAG) ;

check-status:
	@. $(RELEASE_SUPPORT) ; ! hasChanges || (echo "ERROR: there are still outstanding changes" >&2 && exit 1) ;

check-release:
	@. $(RELEASE_SUPPORT) ; tagExists $(TAG) || (echo "ERROR: version not yet tagged in git. make [minor,major,patch]-release." >&2 && exit 1) ;
	@. $(RELEASE_SUPPORT) ; ! differsFromRelease $(TAG) || (echo "ERROR: current directory differs from tagged $(TAG). make [minor,major,patch]-release." ; exit 1)
