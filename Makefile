HUGO := docker run -v $(PWD):/work --rm blog.s-tajima.work/hugo

init:
	docker build -t blog.s-tajima.work/hugo .

build:
	rm -rf docs/*
	echo "blog.s-tajima.work" > docs/CNAME
	$(HUGO)

preview:
	$(HUGO) server -t hugo-future-imperfect-custom --port=11313 --disableFastRender

post: check/title
	$(HUGO) new post/$(shell date +"%Y")/$(TITLE)/index.md

check/title:
	@[ "$(TITLE)" != "" ] || (echo "You have to specify TITLE." && exit 1)
