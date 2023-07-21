PBDIR := $(realpath $(PWD))

dns vpn-server vpn-controller:
	make -f $(PBDIR)/../Makefile NAME=poc-$@-container	\
		DOCKERFILE_DIRECTORY=$(PBDIR)/poc-$@-container \
		DOCKER_FILE_PATH=$(PBDIR)/poc-$@-container/Dockerfile 

include $(PBDIR)/deps.mk
