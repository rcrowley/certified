all:
	git checkout -q master
	-cp share/html/* .
	git checkout -q gh-pages
	-git add .
	-git commit -mgh-pages

.PHONY: all
