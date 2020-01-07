#!/usr/bin/make -f

empty :=
close_paren := $(empty))$(empty)

GIT_VERSION := $(shell git rev-parse --short HEAD)
GIT_BRANCH := $(shell git branch --list | sed -n '/^\*/{s/^\* //;s/.* rebasing \(.*\)$(close_paren)$$/\1/;p}')

IMAGE_PREFIX := docker.brainfood.com/shared

OTHER_IMAGES := dockergen mariadb-10.1 mariadb-10.4 nexus3 node postgresql roundcube
DEBIAN_BASES := jessie-slim stretch-slim buster-slim
JESSIE_IMAGES := mysql-5.5 php5
STRETCH_IMAGES := dovecot file-access java8 nginx php7 postfix squid
BUSTER_IMAGES := bind9 nextcloud

ALL_IMAGES += $(DEBIAN_BASES)
ALL_IMAGES += $(JESSIE_IMAGES)
$(patsubst %,$(IMAGE_PREFIX)/%,$(JESSIE_IMAGES)): $(IMAGE_PREFIX)/jessie-slim
ALL_IMAGES += $(STRETCH_IMAGES)
$(patsubst %,$(IMAGE_PREFIX)/%,$(STRETCH_IMAGES)): $(IMAGE_PREFIX)/stretch-slim
ALL_IMAGES += $(BUSTER_IMAGES)
$(patsubst %,$(IMAGE_PREFIX)/%,$(BUSTER_IMAGES)): $(IMAGE_PREFIX)/buster-slim

all: $(patsubst %,$(IMAGE_PREFIX)/%,$(ALL_IMAGES)) $(patsubst %,$(IMAGE_PREFIX)/%,$(OTHER_IMAGES))
other: $(patsubst %,$(IMAGE_PREFIX)/%,$(OTHER_IMAGES))
bases: $(patsubst %,$(IMAGE_PREFIX)/%,$(DEBIAN_BASES))
jessie: $(patsubst %,$(IMAGE_PREFIX)/%,$(JESSIE_IMAGES))
stretch: $(patsubst %,$(IMAGE_PREFIX)/%,$(STRETCH_IMAGES))
buster: $(patsubst %,$(IMAGE_PREFIX)/%,$(BUSTER_IMAGES))

$(patsubst %,$(IMAGE_PREFIX)/%,$(OTHER_IMAGES)): $(IMAGE_PREFIX)/%: Dockerfile.%
	docker build --build-arg VERSION=$(GIT_BRANCH) -t $(IMAGE_PREFIX)/$*:$(GIT_VERSION) -t $(IMAGE_PREFIX)/$*:$(GIT_BRANCH) -f Dockerfile.$* .

$(patsubst %,$(IMAGE_PREFIX)/%,$(ALL_IMAGES)): $(IMAGE_PREFIX)/%: Dockerfile.%
	docker build --build-arg VERSION=$(GIT_BRANCH) --target=script-base -t $(IMAGE_PREFIX)/$*-script:$(GIT_VERSION) -t $(IMAGE_PREFIX)/$*-script:$(GIT_BRANCH) -f Dockerfile.$* .
	docker build --build-arg VERSION=$(GIT_BRANCH) --target=image-base -t $(IMAGE_PREFIX)/$*-base:$(GIT_VERSION) -t $(IMAGE_PREFIX)/$*-base:$(GIT_BRANCH) -f Dockerfile.$* .
	docker build --build-arg VERSION=$(GIT_BRANCH) --target=final-output -t $(IMAGE_PREFIX)/$*:$(GIT_VERSION) -t $(IMAGE_PREFIX)/$*:$(GIT_BRANCH) -f Dockerfile.$* .

$(IMAGE_PREFIX)/roundcube: $(IMAGE_PREFIX)/php7
$(IMAGE_PREFIX)/mariadb-10.4 $(IMAGE_PREFIX)/node $(IMAGE_PREFIX)/postgresql $(IMAGE_PREFIX)/roundcube: $(IMAGE_PREFIX)/%: Dockerfile.%
	docker build --build-arg VERSION=$(GIT_BRANCH) --target=script-base -t $(IMAGE_PREFIX)/$*-script:$(GIT_VERSION) -t $(IMAGE_PREFIX)/$*-script:$(GIT_BRANCH) -f Dockerfile.$* .
	docker build --build-arg VERSION=$(GIT_BRANCH) --target=image-base -t $(IMAGE_PREFIX)/$*-base:$(GIT_VERSION) -t $(IMAGE_PREFIX)/$*-base:$(GIT_BRANCH) -f Dockerfile.$* .
	docker build --build-arg VERSION=$(GIT_BRANCH) --target=final-output -t $(IMAGE_PREFIX)/$*:$(GIT_VERSION) -t $(IMAGE_PREFIX)/$*:$(GIT_BRANCH) -f Dockerfile.$* .

.PHONY: all other bases jessie stretch buster
.PHONY: $(patsubst %,$(IMAGE_PREFIX)/% bf-%, $(ALL_IMAGES) $(OTHER_IMAGES))

$(patsubst %,bf-%,$(ALL_IMAGES)): bf-%: $(IMAGE_PREFIX)/%
