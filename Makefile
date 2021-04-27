DEV         := .dev
BIN         := $(DEV)/bin
BUILD       := $(DEV)/build
CONFIG      := $(DEV)/config
SOURCES     := src
VENDORBIN   := vendor/bin
PHPLOC      := $(BIN)/phploc
PHPCS       := $(BIN)/phpcs
PHPCS_CFG   := $(CONFIG)/phpcs.xml
PHPCBF      := $(BIN)/phpcbf
PHPCPD      := $(BIN)/phpcpd
PHPMD       := $(BIN)/phpmd
PHPMD_CFG   := $(CONFIG)/phpmd.xml
PHPSTAN     := $(VENDORBIN)/phpstan
PHPSTAN_CFG := $(CONFIG)/phpstan.neon
PHPUNIT     := $(VENDORBIN)/phpunit
PHPUNIT_CFG := $(CONFIG)/phpunit.xml

all:
	@echo "Review the file 'Makefile' to see what targets are supported."

clean:
	rm -rf $(BUILD) .phpunit.result.cache

clean-all: clean
	rm -rf $(BIN) vendor composer.lock

install: install-php-tools
	[ ! -f composer.json ] || composer install

install-php-tools:
	install -d $(BIN)

	# phploc
	curl -Lso $(PHPLOC) https://phar.phpunit.de/phploc.phar && chmod 755 $(PHPLOC)

	# phpcs
	curl -Lso $(PHPCS) https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar && chmod 755 $(PHPCS)

	# phpcbf
	curl -Lso $(PHPCBF) https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar && chmod 755 $(PHPCBF)

	# phpcpd
	curl -Lso $(PHPCPD) https://phar.phpunit.de/phpcpd.phar && chmod 755 $(PHPCPD)

	# phpmd
	curl -Lso $(PHPMD) https://github.com/phpmd/phpmd/releases/download/2.9.1/phpmd.phar && chmod 755 $(PHPMD)

	# phpstan
	composer require phpstan/phpstan --dev

	# phpunit
	composer require phpunit/phpunit --dev

check-version:
	uname -a
	@which make
	make --version
	@which php
	php --version
	@which composer
	composer --version
	$(PHPLOC) --version
	$(PHPCS) --version
	$(PHPCBF) --version
	$(PHPCPD) --version
	$(PHPMD) --version
	$(PHPSTAN) --version
	$(PHPUNIT) --version

prepare:
	[ -d $(BUILD) ] || install -d $(BUILD)
	rm -rf $(BUILD)/*

phploc: prepare
	[ ! -d src ] || $(PHPLOC) $(SOURCES) | tee $(BUILD)/$@

phpcs: prepare
	[ ! -f $(PHPCS_CFG) ] || $(PHPCS) --standard=$(PHPCS_CFG) | tee $(BUILD)/$@

phpcbf:
	[ ! -f $(PHPCS_CFG) ] || $(PHPCBF) --standard=$(PHPCS_CFG) | tee $(BUILD)/$@

phpcpd: prepare
	$(PHPCPD) $(SOURCES) | tee $(BUILD)/$@

phpmd: prepare
	- [ ! -f $(PHPMD_CFG) ] || $(PHPMD) . text $(PHPMD_CFG) | tee $(BUILD)/$@

phpstan: prepare
	- [ ! -f $(PHPSTAN_CFG) ] || $(PHPSTAN) analyse -c $(PHPSTAN_CFG) | tee $(BUILD)/$@

phpunit: prepare
	[ ! -f $(PHPUNIT_CFG) ] || XDEBUG_MODE=coverage $(PHPUNIT) --configuration $(PHPUNIT_CFG) $(options) | tee $(BUILD)/$@

cs: phpcs

lint: cs phpcpd phpmd phpstan

test: lint phpunit
	composer validate

metric: phploc


#
# OLDER, clean up eventually
#

# phpcbf:
# ifneq ($(wildcard test),)
# 	- [ ! -f $(PHPCS_CFG) ] || $(PHPCBF) --standard=$(PHPCS_CFG)
# else
# 	- [ ! -f $(PHPCS_CFG) ] || $(PHPCBF) --standard=$(PHPCS_CFG) src
# endif

# phpmd: prepare
# 	- [ ! -f .phpmd.xml ] || [ ! -d src ] || $(PHPMD) . text .phpmd.xml | tee build/phpmd

# phpunit: prepare
# 	[ ! -d test ] || XDEBUG_MODE=coverage $(PHPUNIT) --configuration .phpunit.xml $(options) | tee build/phpunit
