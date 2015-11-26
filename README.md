# Template Docker Makefile
This is a template Makefile for building and releasing Docker images and build the Docker image based on your git tag.


The release of your docker image is kept in the file .release and uses the following format:

	<major>.<minor>.<patch>

the git tag will have the format:

	docker-$(NAME)-<major>.<minor>.<patch>

and will allow you to tag different Docker containers in a single Git repository.



The Makefile has the following targets:
```
make patch-release	increments the patch release level
make minor-release	increments the minor release level and sets patch level to 0
make major-release	increments the major release level and sets both minor and patch level to 0
make build		builds a new version of your Docker image and tags it
make release		builds a new version of your Docker images and pushes it to your repository
make check-status	will check whether there are outstanding changes 
make check-release	will check whether the current directory matches the tagged release in git.
```

