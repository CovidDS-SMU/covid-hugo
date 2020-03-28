.POSIX:
DESTDIR=public

GHP_REPO=git@github.com:CovidDS-SMU/covidds-smu.github.io.git

DOCKER_IMAGE?=klakegg/hugo
DOCKER_TAG?=0.68.3-ext-pandoc


OPTIMIZE = find $(DESTDIR) -not -path "*/static/*" \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) -print0 | \
xargs -0 -P8 -n2 mogrify -strip -thumbnail '1000>'

.PHONY: all
all: get_repository clean build test deploy

.PHONY: get_repository
get_repository:
	@echo "🛎 Getting Pages repository"
	git clone $(GHP_REPO) $(DESTDIR)

.PHONY: clean
clean:
	@echo "🧹 Cleaning old build"
	cd $(DESTDIR) && rm -rf *

# .PHONY: get
# get:
# 	@echo "❓ Checking for hugo"
# 	@if ! [ -x "$$(command -v hugo)" ]; then\
# 		echo "🤵 Getting Hugo";\
# 	    wget -q -P tmp/ https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_extended_$(HUGO_VERSION)_Linux-64bit.tar.gz;\
# 		tar xf tmp/hugo_extended_$(HUGO_VERSION)_Linux-64bit.tar.gz -C tmp/;\
# 		sudo mv -f tmp/hugo /usr/bin/;\
# 		rm -rf tmp/;\
# 		hugo version;\
# 	fi

.PHONY:server
server:
	docker run --rm -it \
	-v $(shell pwd):/src \
	-p 1313:1313 \
	$(DOCKER_IMAGE):$(DOCKER_TAG) server -$(args)

.PHONY: shell
shell:
	docker run --rm -it \
	-v $(shell pwd):/src \
	-v $(shell pwd)/public:/$(DESTDIR) \
	-e HUGO_PANDOC="pandoc-default --strip-empty-paragraphs" \
	$(DOCKER_IMAGE):$(DOCKER_TAG) \
	shell

.PHONY: build
build:
	@echo "🍳 Generating site"
	docker run --rm -it \
	-v $(shell pwd):/src \
	-e HUGO_PANDOC="pandoc-default --strip-empty-paragraphs" \
	$(DOCKER_IMAGE):$(DOCKER_TAG) \
	--gc --minify -d $(DESTDIR)
	@echo "🧂 Optimizing images"

.PHONY: test
test:
	@echo "🍜 Testing HTML"
	docker run -v $(GITHUB_WORKSPACE)/$(DESTDIR)/:/mnt 18fgsa/html-proofer mnt --disable-external

.PHONY: deploy
deploy:
	@echo "🎁 Preparing commit"
	@cd $(DESTDIR) \
	&& git add . \
	&& git status \
	&& git commit -m "🤖 CD bot is helping" \
	&& git push -f -q $(GHP_REPO) master
	@echo "🚀 Site is deployed!"