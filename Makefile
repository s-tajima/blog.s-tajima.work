HUGO := bin/hugo

build:
	rm -rf docs/*
	$(HUGO)

preview:
	$(HUGO) server -t hugo-future-imperfect-custom --port=11313

post: check/title
	$(HUGO) new post/$(shell date +"%Y")/$(TITLE)/index.md

check/title:
	@[ "$(TITLE)" != "" ] || (echo "You have to specify TITLE." && exit 1)
