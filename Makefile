HUGO_IMAGE := blog.s-tajima.work/hugo
HUGO := docker run -v $(PWD):/work -p 127.0.0.1:11313:11313 --rm $(HUGO_IMAGE)

init:
	docker build -t $(HUGO_IMAGE) .

build:
	rm -rf docs/*
	echo "blog.s-tajima.work" > docs/CNAME
	$(HUGO)

preview:
	$(HUGO) server -t hugo-future-imperfect-custom --bind 0.0.0.0 --port=11313 --disableFastRender

post: check/title
	$(HUGO) new post/$(shell date +"%Y")/$(TITLE)/index.md

check/title:
	@[ "$(TITLE)" != "" ] || (echo "You have to specify TITLE." && exit 1)
