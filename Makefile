SHELL := /bin/bash
ROOT  := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
DATE  := $(shell date '+%Y%m%d-%H%M%S')

RSYNC             = rsync --archive --verbose --compress --rsh='ssh -o ClearAllForwardings=yes'
REMOTE_HOST       = pp-wandb
REMOTE_PATH       = projects/wandb

WANDB_HOST       ?= 127.0.0.1
WANDB_PORT       ?= 18080
WANDB_DATA       ?= $(ROOT)/data/docker

DOCKER_NAME       = wandb/local
DOCKER_VERSION    = 0.85.1

# -----------------------------------------------------------------------------
# defaults
# -----------------------------------------------------------------------------

.DEFAULT_GOAL = run

# -----------------------------------------------------------------------------
#
# run
#
# https://github.com/wandb/server
# https://hub.docker.com/r/wandb/local
# https://docs.coreweave.com/products/wandb/platform/hosting/hosting-options/self-managed
# https://docs.coreweave.com/products/wandb/platform/hosting/env-vars
# -----------------------------------------------------------------------------

.PHONY: banner
banner:
	@echo "connect to: http://${WANDB_HOST}:${WANDB_PORT}/"

.PHONY: folders
folders:
	@mkdir -p -m 777 "$(WANDB_DATA)"

.PHONY: run
run: folders banner
	@docker run \
		--name "wandb-server-${USER}" \
		--hostname="wandb-server" \
		--rm \
		--interactive \
		--tty \
		--volume "$(WANDB_DATA):/vol:rw" \
		--publish "${WANDB_HOST}:${WANDB_PORT}:8080/tcp" \
		"$(DOCKER_NAME):$(DOCKER_VERSION)"

# -----------------------------------------------------------------------------
# rsync
# -----------------------------------------------------------------------------

.PHONY: rsync-push
rsync-push:
	@$(RSYNC) --delete \
		--exclude='/.git' \
		--exclude='/.idea' \
		--exclude='/data/*' \
		'$(ROOT)/' \
		'$(REMOTE_HOST):$(REMOTE_PATH)'

.PHONY: rsync-pull
rsync-pull:
	@$(RSYNC) \
		--exclude='/.git' \
		--exclude='/.idea' \
		--exclude='/data/*' \
		'$(REMOTE_HOST):$(REMOTE_PATH)' \
		'$(ROOT)/'
