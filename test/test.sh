#!/bin/bash
set -e

. ../.make-release-support

cat > .release <<!
release=0.0.0
tag=example-0.0.0
!

ERROR=0
function assertEquals() {
	RESULT=$(. ../.make-release-support; $1)
	EXPECT=$2
	if [ "$RESULT" == "$EXPECT" ] ; then
		echo "Success: $1 == $EXPECT"
	else
		echo "ERROR: $1, Expected $EXPECT, got $RESULT" 
		ERROR=1
	fi
}

function assertTags() {
	assertEquals getTag example-$1
	assertEquals getBaseTag example-
}

function assertSetRelease() {
	setRelease $1
	assertTags $1
}

function expectedReleaseOutput() {
cat <<!
docker build -t docker.io/mark/test:$1 .
docker tag  -f docker.io/mark/test:$1 docker.io/mark/test:latest
docker push docker.io/mark/test:$1
docker push docker.io/mark/test:$1
}
!
}

function assertMakeRelease() {
	RESULT=$(make -f ../Makefile $1)
	if [ "$RESULT" != "$(expectedReleaseOutput $2)" ]; then
		echo Success: make $1 $2
	else
		echo ERROR: make $1 $2
		echo $RESULT | sed -e 's/^/	/'
		ERROR=1
	fi
}

assertTags 0.0.0
assertEquals 'getRelease' 0.0.0

assertEquals 'nextPatchLevel' 0.0.1
assertSetRelease 0.0.1
assertEquals 'getTag' example-0.0.1

assertEquals 'nextPatchLevel' 0.0.2
assertSetRelease 0.0.2
assertEquals 'nextMinorLevel' 0.1.0
assertSetRelease 0.1.0
assertEquals 'nextMinorLevel' 0.2.0
assertSetRelease 0.2.0
assertEquals 'nextMajorLevel' 1.0.0
assertSetRelease 1.0.0
assertEquals 'nextMajorLevel' 2.0.0
assertSetRelease 2.0.0
assertEquals 'nextPatchLevel' 2.0.1
assertSetRelease 2.0.1
assertEquals 'nextMinorLevel' 2.1.0


rm -rf .git .release
git init 
make -f ../Makefile .release
assertEquals 'getRelease' 0.0.0

#
# Add a dummy docker to the path
#
cat > docker <<!
#!/bin/bash
true
!
chmod +x docker
export PATH=.:$PATH

git add .release test.sh docker
git commit -m "first import"
assertEquals getVersion 0.0.0-$(git rev-parse --short HEAD)

touch new-file
assertEquals getVersion 0.0.0-$(git rev-parse --short HEAD)-dirty
rm new-file

assertMakeRelease patch-release 0.0.1
assertMakeRelease minor-release 0.1.0
assertMakeRelease major-release 1.0.0

rm -rf docker .git .release
