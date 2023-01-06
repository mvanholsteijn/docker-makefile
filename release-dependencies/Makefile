
COMPONENTS=common backend frontend

showimage:	## shows all image versions
	for d in $(COMPONENTS); do (cd $$d ; make showimage) || exit 1; done

tag-patch-release:	## tag patch release for the components, if there are any changes
	for d in $(COMPONENTS); do (cd $$d ; make check-release || make $@) || exit 1; done

