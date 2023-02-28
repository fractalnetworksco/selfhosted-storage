docker:
	# build the docker image
	docker build -f Dockerfile.target -t s4-target:latest .
	docker build -f Dockerfile.agent -t s4-agent:latest .

docker-shell:
	docker run --workdir /var/lib/fractal -v /var/lib/fractal:/var/lib/fractal -v `pwd`:/code --privileged --rm -it --entrypoint ash s4-agent:latest

nsenter:
	# not needed but useful to enter the docker vm
	docker run --privileged --rm --pid=host -it --entrypoint nsenter s4-agent:latest -t 1 -m -u -n -i

# step 0, https://www.reddit.com/r/artixlinux/comments/ovbil4/failed_to_open_devbtrfscontrol/
mknod:
	docker run --privileged --rm --pid=host -it --entrypoint nsenter s4-agent:latest -t 1 -m -u -n -i mknod /dev/btrfs-control c 10 234

# step 1, create a file	
fallocate:
	fallocate -l 1G /var/lib/fractal/btrfs.img

# step2, create a loop device backed by the file
losetup:
	losetup -fP /var/lib/fractal/btrfs.img