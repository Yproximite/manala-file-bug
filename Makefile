.SILENT:
.PHONY: build test

## Colors
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[33m

## Help
help:
	printf "${COLOR_COMMENT}Usage:${COLOR_RESET}\n"
	printf " make [target]\n\n"
	printf "${COLOR_COMMENT}Available targets:${COLOR_RESET}\n"
	awk '/^[a-zA-Z\-\_0-9\.@]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf " ${COLOR_INFO}%-16s${COLOR_RESET} %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

###############
# Environment #
###############

## Setup environment & Install
setup:
	vagrant up --no-provision
	vagrant provision
	vagrant ssh -- "cd /srv/app && make install"

## Update environment
update: export ANSIBLE_TAGS = manala.update
update:
	vagrant provision

## Update ansible
update-ansible: export ANSIBLE_TAGS = manala.update
update-ansible:
	vagrant provision --provision-with ansible

## Provision environment
provision: export ANSIBLE_EXTRA_VARS = {"manala":{"update":false}}
provision:
	vagrant provision --provision-with app

## Provision nginx
provision-nginx: export ANSIBLE_TAGS = manala_nginx
provision-nginx: provision

## Provision php
provision-php: export ANSIBLE_TAGS = manala_php
provision-php: provision

###########
# Install #
###########

## Install application
install: install-git-hooks install-app

install-app:
	ansible-playbook ansible/app.yml

update-app:
	ansible-playbook ansible/app.yml -e db_reset=false

install-git-hooks:
	wget --output-document=.git/hooks/pre-commit https://gist.githubusercontent.com/KuiKui/5d7912eb92bb658ed7f6d9bbfbb27b85/raw/52fd9c0d1a9fd3f65c8fedacb4e8de77acbc864a/pre-commit.sh
	chmod +x .git/hooks/pre-commit

######
# Db #
######

## Init db
init-db:
	app/console doctrine:database:create --if-not-exists
	app/console doctrine:schema:update --force
	yes | app/console doctrine:migration:migrate

init-db@test: export SYMFONY_ENV = test
init-db@test: init-db

## Reset db
reset-db:
	app/console doctrine:database:drop --force --if-exists
	app/console doctrine:database:create
	app/console doctrine:schema:create
	yes | app/console doctrine:migration:migrate

reset-db@test: export SYMFONY_ENV = test
reset-db@test: reset-db
