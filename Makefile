build:
	rm -rf docs/*
	hugo

preview:
	hugo server -t hugo-future-imperfect-custom --port=11313
