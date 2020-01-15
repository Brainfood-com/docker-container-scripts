#!/usr/bin/make -f

empty :=
close_paren := $(empty))$(empty)

GIT_VERSION := $(shell git rev-parse --short HEAD)
GIT_BRANCH := $(shell git branch --list | sed -n '/^\*/{s/^\* //;s/.* rebasing \(.*\)$(close_paren)$$/\1/;p}')

IMAGE_PREFIX := docker.brainfood.com/shared

OTHER_IMAGES := dockergen mariadb-10.1 nexus3 node postgresql

JESSIE_IMAGES := mysql-5.5 php5
STRETCH_IMAGES := dovecot file-access java8 nginx php7 postfix roundcube squid
BUSTER_IMAGES := bind9 nextcloud

ALL_IMAGES += $(OTHER_IMAGES)
ALL_IMAGES += $(JESSIE_IMAGES)
ALL_IMAGES += $(STRETCH_IMAGES)
ALL_IMAGES += $(BUSTER_IMAGES)

all: $(patsubst %,$(IMAGE_PREFIX)/%,$(ALL_IMAGES))
other: $(patsubst %,$(IMAGE_PREFIX)/%,$(OTHER_IMAGES))
jessie: $(patsubst %,$(IMAGE_PREFIX)/%,$(JESSIE_IMAGES))
stretch: $(patsubst %,$(IMAGE_PREFIX)/%,$(STRETCH_IMAGES))
buster: $(patsubst %,$(IMAGE_PREFIX)/%,$(BUSTER_IMAGES))

$(patsubst %,$(IMAGE_PREFIX)/%,$(ALL_IMAGES)): $(IMAGE_PREFIX)/%: Dockerfile.%
	docker build -t $(IMAGE_PREFIX)/$*:$(GIT_VERSION) -t $(IMAGE_PREFIX)/$*:$(GIT_BRANCH) -f Dockerfile.$* .

.PHONY: all other jessie stretch buster
.PHONY: $(patsubst %,$(IMAGE_PREFIX)/% bf-%, $(ALL_IMAGES))

$(patsubst %,bf-%,$(ALL_IMAGES)): bf-%: $(IMAGE_PREFIX)/%

