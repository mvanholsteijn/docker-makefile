
COMPONENTS=common backend frontend

tag-patch-release:	## tag patch release for the components, if there are any changes
	for d in $(COMPONENTS); do (cd $$d ; make check-release || make $@) || exit 1; done

