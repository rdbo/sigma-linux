# sent - plain text presentation tool
# See LICENSE file for copyright and license details.

include config.mk

SRC = sent.c drw.c util.c
OBJ = ${SRC:.c=.o}

all: options sent

options:
	@echo sent build options:
	@echo "CFLAGS   = ${CFLAGS}"
	@echo "LDFLAGS  = ${LDFLAGS}"
	@echo "CC       = ${CC}"

config.h:
	cp config.def.h config.h

.c.o:
	${CC} -c ${CFLAGS} $<

${OBJ}: config.h config.mk

sent: ${OBJ}
	${CC} -o $@ ${OBJ} ${LDFLAGS}

cscope: ${SRC} config.h
	cscope -R -b || echo cScope not installed

clean:
	rm -f sent ${OBJ} sent-${VERSION}.tar.gz

dist: clean
	mkdir -p sent-${VERSION}
	cp -R LICENSE Makefile config.mk config.def.h ${SRC} sent-${VERSION}
	tar -cf sent-${VERSION}.tar sent-${VERSION}
	gzip sent-${VERSION}.tar
	rm -rf sent-${VERSION}

install: all
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -f sent ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/sent
	mkdir -p ${DESTDIR}${MANPREFIX}/man1
	cp sent.1 ${DESTDIR}${MANPREFIX}/man1/sent.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/sent.1

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/sent

.PHONY: all options clean dist install uninstall cscope
