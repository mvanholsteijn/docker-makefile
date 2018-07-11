# Generic Docker Makefile
When working with the Docker hub, two small things bothered me:

1. Waiting for your build to start
2. No easy control over the tags for the images.

To resolve these to issues, I created a generic Makefile that allows you to build and release docker images based upon git tags, whenever you want.

## Makefile targets

The Makefile has the following targets:
```
make patch-release	increments the patch release level, build and push to registry
make minor-release	increments the minor release level, build and push to registry
make major-release	increments the major release level, build and push to registry
make release		build the current release and push the image to the registry
make build		builds a new version of your Docker image and tags it
make snapshot		build from the current (dirty) workspace and pushes the image to the registry 
make check-status	will check whether there are outstanding changes
make check-release	will check whether the current directory matches the tagged release in git.
make showver		will show the current release tag based on the directory content.
```


## How to use it.
copy the Makefile and .make-release-support into your Docker git project:

```bash
wget -O Makefile.mk https://raw.githubusercontent.com/mvanholsteijn/docker-makefile/master/Makefile
wget https://raw.githubusercontent.com/mvanholsteijn/docker-makefile/master/.make-release-support
```

## Change registry, user or image name
By default, the registry is set to docker.io and the user to the current user. To override this, edit the Makefile
and set the variables REGISTRY_HOST, USERNAME and NAME.

```Makefile
include Makefile.mk

REGISTRY_HOST=myregistry.io
USERNAME=mvanholsteijn
NAME=awesome-image
```

## Building an image
to build an image, add a Dockerfile to your directory and type make:

```bash
make
```

##  Release
To make a release and tag it, commit add the changes and type:

```bash
make	patch-release
```

This will bump the patch-release number, build the image and push it to the registry. It will only
release if there are no outstanding changes and the content of the directory equals the tagged content.

Alternatively you can choose 'make minor-release' or 'make major-release' to bump the associated number.

## Release number
The release of your docker image is kept in the file .release and uses the following format:

	release=<major>.<minor>.<patch>

The name of the git tag is kept in the same file, and by default will have the format:

	tag=<directory-name>.<minor>.<patch>

This will allow you to have track and tag multiple images in a single Git repository.

If you want to use a different tag prefix, change it in the .release.

## Image name and tag
The name of the image will be created as follows:

```
	<registry-host>/<username>/<directory name>:<tag>
```

The tag is has the following format:

<table >
<tr><th>format</th><th>when</th></tr>
<tr><td valign=top>&lt;release> </td><td>  the contents of the directory is equal to tagged content in git

</td></tr>
<tr><td valign=top> &lt;release>-&lt;commit> </td><td>  the contents of the directory is not equal to the tagged content
</td>
</tr>
<tr><td valign=top> &lt;release>-&lt;commit>-dirty <td> the contents of the directory has uncommitted changes
</td></tr>
</table>

## Multiple docker images in a single git repository.

If you want to maintain multiple docker images in a single git repository, you can use an alternate setup where the Makefile is located in a  silbing directory.

```
├── multiple-example
│   ├── ...
│   ├── image1
│   │   ├── .release
│   │   ├── Dockerfile
│   │   └── Makefile
│   ├── image2
│   │   ├── .release
│   │   ├── Dockerfile
│   │   └── Makefile
│   └── make
│       ├── .make-release-support
│       ├── Makefile
```

The Makefile in the image directories will include the generic Makefile. In this Makefile you can alter the names and tailor the build by adding pre and post build targets.  Checkout the directory (multiple-example) for an example.



### Create the generic make directory

To create the generic make directory, type:

```bash
mkdir make
cd make
wget  https://raw.githubusercontent.com/mvanholsteijn/docker-makefile/master/Makefile  
wget  https://raw.githubusercontent.com/mvanholsteijn/docker-makefile/master/.make-release-support
```

### Create docker image directory
For each docker images, you create a sibling directory:

```bash
mkdir ../image1
cd ../image1

cat > Makefile <<!
include ../make/Makefile

USERNAME=mvanholsteijn

pre-build:
	@echo do some stuff before the docker build

post-build:
	@echo do some stuff after the docker build
!

```

Now you can use the make build and release instructions to build these images.

### Changing the build context and Dockerfile path and name

Use the `DOCKER_BUILD_CONTEXT`variable to set the path to the context. Set `DOCKER_FILE_PATH` to change the path to the Dockerfile (file name included) you want to use. Using this in conjuction with the `pre-build` and `post-build` targets and a `.dockerignore` file allows you to modify the build context.

```
DOCKER_BUILD_CONTEXT=../..
DOCKER_FILE_PATH=$(DOCKER_BUILD_CONTEXT)/docker/$(NAME)/some.Dockerfile

pre-build: check-env-vars .dockerignore
	cp .dockerignore $(DOCKER_BUILD_CONTEXT)

post-build:
	rm $(DOCKER_BUILD_CONTEXT)/.dockerignore
```

### pre tag command
If you want add the current release to a source file, you can add the property `pre\_tag\_command` to the .release file. 
this command is executed when the .release file is updated and before the tag is placed. In the command @@RELEASE@@ is
replaced with the current release before it is executed. For example:

```
release=0.1.0
tag=v0.1.0
pre_tag_command=sed -i "" -e 's/^version=.*/version="@@RELEASE@@"/' setup.py
```

### Adding --build-arg
If you want to add any command line options to the docker build command, specify the Make 
variable `DOCKER_BUILD_ARGS`. 

The following Makefile, specifies the build argument `TAG_VERSION` to be set to the current value.

```
include ../Makefile
DOCKER_BUILD_ARGS=--build-arg TAG_VERSION=$(VERSION)
```

checkout the example [Make-](./build-arg-example/Makefile) and [Dockerfile](./build-arg-example/Dockerfile).

