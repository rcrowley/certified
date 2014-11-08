VERSION=1.0.0
BUILD=1

prefix=/usr/local
bindir=${prefix}/bin
libdir=${prefix}/lib
mandir=${prefix}/share/man

all: certified_$(VERSION)-$(BUILD)_all.deb share/html/*.html

clean:

install: bin/* lib/* share/man/man*/*.[12345678]
	install -d $(DESTDIR)$(bindir)
	install bin/* $(DESTDIR)$(bindir)
	install -d $(DESTDIR)$(libdir)
	install -m644 lib/* $(DESTDIR)$(libdir)
	install -d $(DESTDIR)$(mandir)/man1
	install -m644 share/man/man1/*.1 $(DESTDIR)$(mandir)/man1

test:
	sh test.sh

uninstall:
	make install DESTDIR=uninstall
	-find uninstall -depth -type f -printf $(DESTDIR)/%P\n | xargs rm -f
	-find uninstall -depth -type d -printf $(DESTDIR)/%P\n | xargs rmdir
	rm -rf uninstall

%.deb: bin/* lib/* share/man/man*/*.[12345678]
	rm -f $@
	make install DESTDIR=install prefix=/usr
	fakeroot fpm -a 'all' \
		--description 'Generate and manage an internal CA for your company' \
		--url 'https://github.com/rcrowley/certified' \
		-m 'Richard Crowley <r@rcrowley.org>' \
		--vendor '' \
		-n certified \
		--category 'misc' \
		--license 'BSD-2-clause' \
		-v $(VERSION)-$(BUILD) \
		-d 'openssl' \
		-C install -p $@ -s dir -t deb usr
	rm -rf install

%.rpm: bin/* lib/* share/man/man*/*.[12345678]
	rm -f $@
	make install DESTDIR=install prefix=/usr
	fakeroot fpm -a 'all' \
		--description 'Generate and manage an internal CA for your company' \
		--url 'https://github.com/rcrowley/certified' \
		-m 'Richard Crowley <r@rcrowley.org>' \
		--vendor '' \
		-n certified \
		--category 'misc' \
		--license 'BSD-2-clause' \
		-v $(VERSION) \
		--iteration $(BUILD) \
		-d 'openssl' \
		-C install -p $@ -s dir -t rpm usr
	rm -rf install

share/man/man1/%.1: share/man/man1/%.1.ronn
	ronn --manual=Certified --roff $<

share/html/%.1.html: share/man/man1/%.1.ronn
	ronn --html --manual=Certified --style=toc $<
	mv $(<:.ronn=.html) $@

.PHONY: all clean install test uninstall
