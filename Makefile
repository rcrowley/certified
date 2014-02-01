all:
	git checkout master share/html
	git rm --cached -r share/html
	cp share/html/* .
	rm -rf share/html
	git add .
	git commit -mgh-pages

.PHONY: all
