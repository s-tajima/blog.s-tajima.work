build:
	rm -rf docs/*
	hugo

preview:
	hugo server -t hugo-future-imperfect-custom --port=11313

post: check/title
	hugo new post/$(shell date +"%Y")/$(TITLE)/index.md

check/title:
	@[ "$(TITLE)" != "" ] || (echo "You have to specify TITLE." && exit 1)
