#
#   Copyright 2015-2023  Xebia Nederland B.V.
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
REGISTRY_HOST=113810520231.dkr.ecr.us-east-1.amazonaws.com
USERNAME=$(git config user.name)
USERNAME=$(USERNAME):-$(USER)

NAME ?= $(shell basename $(CURDIR))
DOCKER_BUILD_CONTEXT=.
DOCKER_FILE_PATH ?= Dockerfile
export DOCKERFILE_DIRECTORY
RELEASEFILE=$(DOCKERFILE_DIRECTORY)/.release

RELEASE_SUPPORT := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/.make-release-support 
IMAGE=$(REGISTRY_HOST)/$(NAME)


VERSION=$(shell cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT) ; getVersion)

TAG=$(shell cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT); getTag)
TAG_WITH_LATEST=always

SHELL=/bin/bash

.PHONY: pre-build docker-build post-build build release patch-release minor-release major-release tag check-status check-release showver \
	push pre-push do-push post-push showimage

build: pre-build docker-build post-build	## builds a new version of your container image
	echo $(RELEASEFILE)


pre-build:


post-build:


pre-push:


post-push:



docker-build: BASE_RELEASE=$(shell cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT) ; getRelease)
docker-build: $(RELEASEFILE)
	sudo docker build $(DOCKER_BUILD_ARGS) -t $(IMAGE):$(VERSION) $(DOCKER_BUILD_CONTEXT) -f $(DOCKER_FILE_PATH) --build-arg NAME=$(NAME) 
	@if [[ $(TAG_WITH_LATEST) != never ]] && ([[ $(TAG_WITH_LATEST) == always ]] || [[ $(BASE_RELEASE) == $(VERSION) ]]); then \
		echo docker tag $(IMAGE):$(VERSION) $(IMAGE):latest >&2; \
		sudo docker tag $(IMAGE):$(VERSION) $(IMAGE):latest; \
	else \
		echo docker rmi --force --no-prune $(IMAGE):latest >&2; \
		sudo docker rmi --force --no-prune $(IMAGE):latest 2>/dev/null; \
	fi

$(RELEASEFILE):
	@echo "release=0.0.0" > $(RELEASEFILE)
	@echo "tag=$(NAME)-0.0.0" >> $(RELEASEFILE)
	@echo "tag_on_changes_in=." >> $(RELEASEFILE)
	@echo INFO: $(RELEASEFILE) created
	@cat $(RELEASEFILE)


release: check-status check-release build push


push: pre-push do-push post-push 

do-push: BASE_RELEASE=$(shell cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT) ; getRelease)
do-push: 
	sudo docker push $(IMAGE):$(VERSION)
	@if [[ $(TAG_WITH_LATEST) != never ]] && ([[ $(TAG_WITH_LATEST) == always ]] || [[ $(BASE_RELEASE) == $(VERSION) ]]); then \
		echo docker push $(IMAGE):latest >&2; \
		sudo docker push $(IMAGE):latest; \
	fi

snapshot: build push				## builds a new version of your container image, and pushes it to the registry

showver: $(RELEASEFILE)				## shows the current release tag based on the workspace
	cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT); getVersion

showimage: $(RELEASEFILE)				## shows the container image name based on the workspace
	@echo $(IMAGE):$(VERSION)

tag-patch-release: VERSION := $(shell cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT); nextPatchLevel)
tag-patch-release: $(RELEASEFILE) tag 		## increments the patch release level and create the tag without build

tag-minor-release: VERSION := $(shell cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT); nextMinorLevel)
tag-minor-release: $(RELEASEFILE) tag 		## increments the minor release level and create the tag without build

tag-major-release: VERSION := $(shell cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT); nextMajorLevel)
tag-major-release: $(RELEASEFILE) tag 		## increments the major release level and create the tag without build

patch-release: tag-patch-release release	## increments the patch release level, build and push to registry
	@echo $(VERSION)

minor-release: tag-minor-release release	## increments the minor release level, build and push to registry
	@echo $(VERSION)

major-release: tag-major-release release	## increments the major release level, build and push to registry
	@echo $(VERSION)


tag: TAG=$(shell cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT); getTag $(VERSION))
tag: check-status
	cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT) ; ! tagExists $(TAG) || (echo "ERROR: tag $(TAG) for version $(VERSION) already tagged in git" >&2 && exit 1) ;
	cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT) ; setRelease $(VERSION)
	git add .
	git commit -m "bumped to version $(VERSION)" ;
	git tag $(TAG) ;
	@ if [ -n "$(shell git remote -v)" ] ; then git push --tags ; else echo 'no remote to push tags to' ; fi

check-status:			## checks whether there are outstanding changes
	cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT) ; ! hasChanges || (echo "ERROR: there are still outstanding changes" >&2 && showChanges >&2 && exit 1) ;

check-release: $(RELEASEFILE)		## checks whether the workspace matches the tagged release in git
	cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT) ; tagExists $(TAG) || (echo "ERROR: version not yet tagged in git. make [minor,major,patch]-release." >&2 && exit 1) ;
	cd $(DOCKERFILE_DIRECTORY); . $(RELEASE_SUPPORT) ; ! differsFromRelease $(TAG) || (echo "ERROR: current directory differs from tagged $(TAG). make [minor,major,patch]-release." && showDiffFromRelease >&2 ; exit 1)


help:           ## show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | grep -v fgrep | sed -e 's/\([^:]*\):[^#]*##\(.*\)/printf '"'%-20s - %s\\\\n' '\1' '\2'"'/' |bash
