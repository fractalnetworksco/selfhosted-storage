
plugin:
	# clean up
	docker plugin rm -f fractalnetworks/s4-plugin:latest || true
	docker rm s4_plugin_container_tmp || true
	rm -rf plugin rootfs.tar.gz; mkdir -p plugin/rootfs
	# build
	docker build -t s4_plugin_tmp .
	docker create --name s4_plugin_container_tmp s4_plugin_tmp
	docker export s4_plugin_container_tmp | gzip > rootfs.tar.gz
	tar -xzf rootfs.tar.gz -C plugin/rootfs
	cp config.json plugin/config.json
	# create plugin
	docker plugin create fractalnetworks/s4-plugin:latest plugin
	# enable plugin
	docker plugin enable fractalnetworks/s4-plugin:latest
	# clean up
	rm -rf plugin rootfs.tar.gz

.PHONY: plugin