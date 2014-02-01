VERSION=0.0.0
BUILD=0

prefix=/usr/local
bindir=${prefix}/bin
libdir=${prefix}/lib
mandir=${prefix}/share/man

all: certified_$(VERSION)-$(BUILD)_all.deb share/html/*.html
	$(MAKE) -C share/html

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
	fakeroot fpm -Cinstall -m'Richard Crowley <r@rcrowley.org>' -ncertified -v$(VERSION)-$(BUILD) -p$@ -sdir -tdeb usr
	rm -rf install

share/man/man1/%.1: share/man/man1/%.1.ronn
	ronn --manual=Certified --roff $<

share/html/%.1.html: share/man/man1/%.1.ronn
	ronn --html --manual=Certified --style=toc $<
	mv $(<:.ronn=.html) $@

.PHONY: all clean install test uninstall
