#Copyright (c) 2014 Ashley Jeffs
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

.PHONY: all build lint check clean install example multiplat package

PROJECT := leaps
VERSION := $(shell git describe --tags || echo "v0.0.0")

all: build

build: check
	@mkdir -p ./bin
	@echo "building ./bin/$(PROJECT)"
	@go build -o ./bin/$(PROJECT)

GOLINT=$(shell golint .)
lint:
	@go tool vet ./**/*.go && echo "$(GOLINT)" && test -z "$(GOLINT)" && jshint ./leapclient/*.js

check: lint
	@go test ./...
	@cd leapclient; find . -maxdepth 1 -name "test_*" -exec nodeunit {} \;
	@echo ""; echo " -- Testing complete -- "; echo "";

clean:
	@find $(GOPATH)/pkg/*/github.com/jeffail -name $(PROJECT).a -delete
	@rm -rf ./bin

install: check
	@go install

PLATFORMS = "darwin/amd64" "freebsd/amd64" "freebsd/arm" "linux/amd64" "linux/arm" "windows/amd64"
multiplatform_builds = $(foreach platform, $(PLATFORMS), \
		plat="$(platform)" GOOS="$${plat%/*}" GOARCH="$${plat\#*/}" GOARM=7; \
		bindir="./bin/$${GOOS}_$${GOARCH}" exepath="$${bindir}/$(PROJECT)"; \
		echo "building $${exepath} with GOOS=$${GOOS}, GOARCH=$${GOARCH}, GOARM=$${GOARM}"; \
		mkdir -p "$$bindir"; GOOS=$$GOOS GOARCH=$$GOARCH GOARM=$$GOARM go build -o "$$exepath"; \
	)

package_builds = $(foreach platform, $(PLATFORMS), \
		plat="$(platform)" p_stamp="$${plat%/*}_$${plat\#*/}" a_name="$(PROJECT)-$${p_stamp}-$(VERSION)"; \
		echo "archiving $${a_name}"; \
		mkdir -p "./releases/$(VERSION)"; \
		cp -LR "./bin/$${p_stamp}" "./releases/$(VERSION)/$(PROJECT)"; \
		cp -LR "./config" "./releases/$(VERSION)/$(PROJECT)"; \
		cp -LR "./static" "./releases/$(VERSION)/$(PROJECT)"; \
		cd "./releases/$(VERSION)"; \
		tar -czf "$${a_name}.tar.gz" "./$(PROJECT)"; \
		rm -r "./$(PROJECT)"; \
		cd ../..; \
	)

multiplat: check
	@$(multiplatform_builds)

package: multiplat
	@$(package_builds)

example: install
	@$(PROJECT) -c ./config/leaps_example.js