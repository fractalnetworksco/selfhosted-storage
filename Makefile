SHELL = '/bin/bash'
docker:
	docker pull alpine:latest
	# build the docker image
	docker build -f Dockerfile.target -t s4-target:latest .
	docker build -f Dockerfile.agent -t s4-agent:latest .

# use this to run s4 with docker desktop
docker-desktop-shell:
	docker run -it --privileged --rm --workdir /var/lib/fractal -v $(DATA_DIR):/data -v /var/lib/fractal:/var/lib/fractal -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`:/code --entrypoint bash s4-agent:latest

shell:
	docker run -it --privileged --workdir /s4 --rm -v $(VOLUME):/s4 -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`:/code --entrypoint bash s4-agent:latest

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

target: docker
	docker rm -f s4-target-dev || true
	docker run --name s4-target-dev -v /mnt/catalogs:/catalogs -v /mnt/volumes:/volumes --restart always -p 2222:22 -d s4-target:latest

install:
	sudo ln -s `pwd`/s4.sh /usr/local/bin/s4


borg:
	sudo apt install libacl1-dev
	pip install borgbackup

agent-export: docker
	docker save -o s4-agent.tar s4-agent:latest

# test: docker
# 	ssh-keygen -t ed25519 -f id_ed25519-ci -q -N "" -y; \
# 	echo -e "S4_PUB_KEY=\"$$(cat id_ed25519-ci.pub)\"\nS4_PRIV_KEY=\"$$(cat id_ed25519-ci)\"" > ci_credentials.env; \
# 	docker build -t s4-test:latest -f Dockerfile.test .; \
#	cd tests/ && docker compose up --exit-code-from s4-test

test: 
	echo "Hello World" > testfile123
	ssh-keygen -t ed25519 -f id_ed25519-ci -q -N "" -y; 

