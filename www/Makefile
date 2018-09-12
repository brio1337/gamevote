OS_NAME := $(shell uname)

ifndef OS_NAME
$(error uname failed)
endif

.PHONY: install-$(OS_NAME)
install-$(OS_NAME):

install-Linux:
	sudo apt install npm nodejs-legacy
	sudo setcap 'cap_net_bind_service=+ep' $$(readlink -f $$(which node))

install-Darwin:
	brew install node

.PHONY: install-npm
install-npm: install-$(OS_NAME)
	rm -rf node_modules
	npm install

.PHONY: install-service
install-service: install-npm
	cp node.service /etc/systemd/system/
	systemctl enable node

cert.pem:
	openssl req -x509 -newkey rsa:2048 -nodes \
		-subj "/C=CA/ST=BC/L=Victoria/O=brio o/OU=brio ou/CN=brio.software" \
		-out cert.pem -keyout key.pem

.PHONY: install-local
install-local: install-npm cert.pem

.PHONY: deploy-claudia
deploy-claudia:
	AWS_PROFILE=claudia claudia update
