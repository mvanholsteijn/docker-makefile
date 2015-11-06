#
# Edit the REGISTRY_HOST, USERNAME and NAME as required
#
REGISTRY_HOST=
USERNAME=$(shell whoami)
NAME=$(shell basename $(PWD))

IMAGE=$(REGISTRY_HOST)$(USERNAME)/$(NAME)

VERSION=$(shell . .make-release-support ; getVersion)

build: 
	docker build --no-cache --force-rm -t $(IMAGE):$(VERSION) .
	docker tag  -f $(IMAGE):$(VERSION) $(IMAGE):latest

release: check-status check-release build
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):$(VERSION)

patch-release: VERSION = $(shell . .make-release-support; nextPatchLevel)
patch-release: tag 

minor-release: VERSION = $(shell . .make-release-support; nextMinorLevel)
minor-release: tag 

major-release: VERSION = $(shell . .make-release-support; nextMajorLevel)
major-release: tag 

tag: check-status
	@. .make-release-support ; ! tagExists || (echo "ERROR: version $(VERSION) already tagged in git" >&2 && exit 1) ; 
	@echo $(VERSION) > .release 
	git add .release 
	git commit -m "bumped to version $(VERSION)" ; 
	git tag $(VERSION) ;
	@test -z "$(shell git remote -v)" || git push --tags

check-status:
	@. .make-release-support ; ! hasChanges || (echo "ERROR: there are still outstanding changes" >&2 && exit 1) ; 

check-release: 
	@. .make-release-support ; tagExists || (echo "ERROR: version not yet tagged in git" >&2 && exit 1) ; 
	@. .make-release-support ; ! differsFromRelease || (echo "ERROR: current directory differs from tagged $$(<.release). make [minor,major,patch]-release." ; exit 1) 

